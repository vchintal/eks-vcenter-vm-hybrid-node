variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "eks_version" {
  type        = string
  description = "EKS cluster version"
}

variable "customer_gateway_ip_address" {
  description = "Public IP address of the on-premise client gateway"
  type        = string
}

variable "local_ipv4_network_cidr" {
  description = "This is the on-premise network CIDR to be shared over the VPN"
  type        = string
}

variable "remote_ipv4_network_cidr" {
  description = "This is the AWS network CIDR to be shared over the VPN"
  type        = string
}

variable "remote_node_network_cidr" {
  description = "This is on-premise node network CIDR where the Hybrid nodes will reside"
  type        = string
}

variable "remote_pod_network_cidr" {
  description = "This is the on-premise pod network CIDR for the Hybrid nodes"
  type        = string
}

variable "enable_s2s_vpn" {
  description = "Enable Site-to-Site VPN for the VPC"
  type        = bool
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

variable "iso_template_name" {
  type        = string
  description = "ISO based vSphere VM based template name for Hybrid nodes"
}

variable "bottlerocket_template_name" {
  type        = string
  description = "Bottlerocket based vSphere VM based template name for Hybrid nodes"
}

variable "os_bottlerocket" {
  type        = bool
  description = "Use Bottlerocket OS for Hybrid nodes"
  default     = true
}

variable "hybrid_node_count" {
  type        = number
  description = "Number of Hybrid nodes to create"
}