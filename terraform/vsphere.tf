provider "vsphere" {
  # Configuration options
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

locals {
  iso_userdata = templatefile("iso-user-data.yaml", {
    aws_ssm_activation_code = aws_ssm_activation.this.activation_code
    aws_ssm_activation_id   = aws_ssm_activation.this.id
    eks_cluster_name        = var.eks_cluster_name
    aws_region              = var.aws_region
    ssh_public_key          = tls_private_key.this.public_key_openssh
  })
}

data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "iso_template" {
  name          = var.iso_template_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "bottlerocket_template" {
  name          = var.bottlerocket_template_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "default" {
  name          = format("%s%s", data.vsphere_compute_cluster.cluster.name, "/Resources")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
  name          = "vsphere.intrepid.home"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.this.private_key_openssh
  filename        = "eks-hybrid-node-vsphere"
  file_permission = "0400"
}

################################################################################
# EKS Hybrid Node VM based on Ubuntu 24.04 Template
################################################################################
resource "vsphere_virtual_machine" "eks_hybrid_node" {
  count            = var.os_bottlerocket ? 0 : var.hybrid_node_count
  name             = "eks-hybrid-node-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 2
  memory           = 4096
  guest_id         = data.vsphere_virtual_machine.iso_template.guest_id
  scsi_type        = data.vsphere_virtual_machine.iso_template.scsi_type

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.iso_template.disks.0.size
    thin_provisioned = data.vsphere_virtual_machine.iso_template.disks.0.thin_provisioned
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.iso_template.id
  }

  extra_config = {
    "guestinfo.userdata"          = base64encode(local.iso_userdata)
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata" = base64encode(templatefile("iso-metadata.yaml", {
      node_name    = "eks-hybrid-node-${count.index + 1}"
      cluster_name = module.eks.cluster_name # Creates implicit dependency on EKS module
    }))
    "guestinfo.metadata.encoding" = "base64"
  }
}

################################################################################
# EKS Hybrid Node VM based on BottleRocket OS Template
################################################################################
resource "vsphere_virtual_machine" "eks_hybrid_node_br" {
  count                = var.os_bottlerocket ? var.hybrid_node_count : 0
  name                 = "eks-hybrid-node-bottlerocket-${count.index + 1}"
  datastore_id         = data.vsphere_datastore.datastore.id
  host_system_id       = data.vsphere_host.host.id
  resource_pool_id     = data.vsphere_resource_pool.default.id
  num_cpus             = data.vsphere_virtual_machine.bottlerocket_template.num_cpus
  num_cores_per_socket = data.vsphere_virtual_machine.bottlerocket_template.num_cores_per_socket
  memory               = data.vsphere_virtual_machine.bottlerocket_template.memory
  guest_id             = data.vsphere_virtual_machine.bottlerocket_template.guest_id
  firmware             = data.vsphere_virtual_machine.bottlerocket_template.firmware
  scsi_type            = "pvscsi"

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.bottlerocket_template.disks.0.size
    thin_provisioned = data.vsphere_virtual_machine.bottlerocket_template.disks.0.thin_provisioned
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.bottlerocket_template.id
  }

  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0

  extra_config = {
    "guestinfo.userdata" = base64encode(templatefile("br-settings.toml", {
      cluster_name = module.eks.cluster_name
      api_server   = module.eks.cluster_endpoint
      cluster_ca   = module.eks.cluster_certificate_authority_data
      hostname     = "eks-hybrid-node-bottlerocket"
      aws_region   = var.aws_region
      hostname     = "eks-hybrid-node-bottlerocket-${count.index + 1}"
      admin_container_userdata = base64encode(templatefile("br-admin-container-userdata.json", {
        ssh_public_key = trimspace(tls_private_key.this.public_key_openssh)
      }))
      bootstrap_container_userdata = base64encode(templatefile("br-bootstrap-container-userdata.sh", {
        activation_code = aws_ssm_activation.this.activation_code
        activation_id   = aws_ssm_activation.this.id
        aws_region      = var.aws_region
      }))
    }))
    "guestinfo.userdata.encoding" = "base64"
  }
}
