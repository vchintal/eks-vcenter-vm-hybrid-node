variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_cluster_name" {
  description = "Name of EKS cluster"
  type        = string
  default     = "eks-cluster-1"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "eks_version" {
  type        = string
  description = "EKS cluster version"
  default     = "1.34"
}

variable "customer_gateway_ip_address" {
  description = "Public IP address of the on-premise client gateway"
  type        = string
}

variable "local_ipv4_network_cidr" {
  description = "This is the on-premise network CIDR to be shared over the VPN"
  type        = string
  default     = "192.168.1.0/24"
}

variable "remote_ipv4_network_cidr" {
  description = "This is the AWS network CIDR to be shared over the VPN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "remote_node_network_cidr" {
  description = "This is on-premise node network CIDR where the Hybrid nodes will reside"
  type        = string
  default     = "192.168.1.0/26"
}

variable "remote_pod_network_cidr" {
  description = "This is the on-premise pod network CIDR for the Hybrid nodes"
  type        = string
  default     = "192.168.1.64/26"
}

variable "enable_s2s_vpn" {
  description = "Enable Site-to-Site VPN for the VPC"
  type        = bool
  default     = "true"
}

variable "vsphere_server" {
  type        = string
  description = "vCenter server address"
}

variable "vsphere_user" {
  type        = string
  description = "vCenter username with permissions to create VM templates"
}

variable "vsphere_password" {
  type        = string
  sensitive   = true
  description = "vCenter password"
}

variable "vsphere_datacenter" {
  type        = string
  description = "vSphere datacenter name"
}

variable "vsphere_cluster" {
  type        = string
  description = "vSphere cluster name"
}

variable "vsphere_datastore" {
  type        = string
  description = "vSphere datastore name"
}

variable "vsphere_network" {
  type        = string
  default     = "VM Network"
  description = "vSphere network name"
}

variable "vsphere_folder" {
  type        = string
  description = "vSphere folder to store the VM template"
}

variable "vm_template_name" {
  type        = string
  description = "vSphere VM template name for Hybrid nodes"
}

variable "hybrid_node_count" {
  type        = number
  description = "Number of Hybrid nodes to create"
  default     = 4
}