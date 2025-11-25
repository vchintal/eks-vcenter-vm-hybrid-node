data "aws_availability_zones" "available" {}

locals {
  name = var.eks_cluster_name
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {}
}

provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.19.0"

  name = format("%s-%s", var.eks_cluster_name, "vpc")
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 10)]

  enable_nat_gateway = true
  single_nat_gateway = true

  # Enable route propagation for VPN Gateway
  propagate_private_route_tables_vgw = true

  # Following settings are optional but helps with monitoring VPC traffic
  # enable_flow_log                                 = true
  # create_flow_log_cloudwatch_log_group            = true
  # create_flow_log_cloudwatch_iam_role             = true
  # flow_log_cloudwatch_log_group_retention_in_days = 7

  # VPN specific settings
  enable_vpn_gateway = var.enable_s2s_vpn ? true : false
  amazon_side_asn    = 64512

  customer_gateways = var.enable_s2s_vpn ? {
    IP1 = {
      bgp_asn    = 65000
      ip_address = var.customer_gateway_ip_address
    }
  } : {}

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

module "vpn_gateway" {
  source  = "terraform-aws-modules/vpn-gateway/aws"
  version = "~> 3.7.0"
  count   = var.enable_s2s_vpn ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  vpn_gateway_id      = module.vpc.vgw_id
  customer_gateway_id = module.vpc.cgw_ids[0]

  # The local_ipv4_network_cidr should match the on-premise network CIDR
  # and the remote_ipv4_network_cidr should match the AWS VPC CIDR
  local_ipv4_network_cidr  = var.local_ipv4_network_cidr
  remote_ipv4_network_cidr = var.remote_ipv4_network_cidr

  vpc_subnet_route_table_count = length(module.vpc.private_route_table_ids)
  vpc_subnet_route_table_ids   = module.vpc.private_route_table_ids

  # Settings specific to VPN connection, choosing static routing
  # The statics routes should match the on-premise network CIDR
  vpn_connection_static_routes_only         = true
  vpn_connection_static_routes_destinations = [var.local_ipv4_network_cidr]

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.8.0"

  name               = var.eks_cluster_name
  kubernetes_version = var.eks_version

  endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Without kube-proxy calls to the API server will via the kubernetes service 
  # private IP will fail
  addons = {
    eks-pod-identity-agent = {}
    kube-proxy             = {}
  }

  # Ensure the entity who created the cluster has admin rights to it
  enable_cluster_creator_admin_permissions = true

  # Enable auto-mode
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  # Hybrid node role module is available
  access_entries = {
    hybrid-node-role = {
      principal_arn = module.eks_hybrid_node_role.arn
      type          = "HYBRID_LINUX"
    }
  }

  remote_network_config = {
    remote_node_networks = {
      cidrs = [var.remote_node_network_cidr]
    }
    remote_pod_networks = {
      cidrs = [var.remote_pod_network_cidr]
    }
  }

  tags = local.tags
}

module "eks_hybrid_node_role" {
  source  = "terraform-aws-modules/eks/aws//modules/hybrid-node-role"
  version = "~> 21.8.0"

  tags = local.tags
}

resource "aws_ssm_activation" "this" {
  name               = "hybrid-node"
  iam_role           = module.eks_hybrid_node_role.name
  registration_limit = var.hybrid_node_count

  tags = local.tags
}

resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.18.3"
  namespace  = "kube-system"
  wait       = false

  values = [
    <<-EOT
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: eks.amazonaws.com/compute-type
              operator: In
              values:
              - hybrid
    ipam:
      mode: cluster-pool
      operator:
        clusterPoolIPv4MaskSize: 28
        clusterPoolIPv4PodCIDRList:
        - ${var.remote_pod_network_cidr}
    loadBalancer:
      serviceTopology: true
    operator:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: eks.amazonaws.com/compute-type
                operator: In
                values:
                  - hybrid
      unmanagedPodWatcher:
        restart: false
    loadBalancer:
      serviceTopology: true
    envoy:
      enabled: false
    kubeProxyReplacement: "false"
    EOT
  ]
}