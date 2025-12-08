packer {
  required_version = ">= 1.11.0"
  required_plugins {
    vsphere = {
      source  = "github.com/hashicorp/vsphere"
      version = ">= 1.4.0"
    }
  }
}

variable "aws_region" {
  type    = string
}

variable "credential_provider" {
  type    = string
  default = "ssm"
}

variable "nodeadm_arch" {
  type        = string
  default     = "amd"
  description = "Architecture for nodeadm install. Choose 'amd' or 'arm'."
}

variable "pkr_ssh_password" {
  description = "Password for Packer to SSH into the VM when provisioning. Have it match the password set in either the ks.cfg or user-data files for the VM."
  default     = "ubuntu"
}

variable "iso_url" {
  type        = string
  description = "URL to the ISO image. Can be a server web link or an absolute path to a local file."
}

variable "iso_checksum" {
  type        = string
  description = "Checksum of the ISO image."
}

variable "eks_version" {
  type        = string
  description = "Kubernetes version to use. Must be 1.30 - 1.34"
}

####################
# vSphere variables
####################
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
  description = "vSphere VM template name for Hybrid nodes"
}

locals {
  timestamp    = formatdate("YYYY-MM-DD-hhmm", timestamp())
  nodeadm_link = "https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/${var.nodeadm_arch}64/nodeadm"
}

source "vsphere-iso" "ubuntu24" {
  vcenter_server      = var.vsphere_server != "" ? var.vsphere_server : " "
  username            = var.vsphere_user != "" ? var.vsphere_user : " "
  password            = var.vsphere_password != "" ? var.vsphere_password : " "
  insecure_connection = true

  datacenter = var.vsphere_datacenter
  cluster    = var.vsphere_cluster != "" ? var.vsphere_cluster : " "
  datastore  = var.vsphere_datastore
  folder     = var.vsphere_folder

  vm_name              = var.iso_template_name
  guest_os_type        = "ubuntu64Guest"
  CPUs                 = 4
  RAM                  = 16384
  disk_controller_type = ["pvscsi"]
  storage {
    disk_size             = 30000
    disk_thin_provisioned = true
  }

  network_adapters {
    network      = var.vsphere_network
    network_card = "vmxnet3"
  }

  boot_order = "disk,cdrom"

  cd_files = ["./http/meta-data", "./http/user-data"]
  cd_label = "cidata"

  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  boot_command = [
    "e<down><down><down><end>",
    " autoinstall ds=nocloud;",
    "<F10>",
  ]

  http_directory = "http"

  communicator = "ssh"
  ssh_username = "ubuntu"
  # default is "ubuntu" as used in http/user-data, make sure to change in both places
  ssh_password = var.pkr_ssh_password
  ssh_timeout  = "30m"

  convert_to_template = true
}

##################################################################
# Generalized build for Ubuntu 22.04/24.04 to install nodeadm
##################################################################
build {
  name = "general-build"

  sources = [
    "source.vsphere-iso.ubuntu24"
  ]

  provisioner "shell" {
    script = "./provisioner_ubuntu.sh"
    environment_vars = [
      "nodeadm_link=${local.nodeadm_link}",
      "k8s_version=${var.eks_version}",
      "credential_provider=${var.credential_provider}",
      "aws_region=${var.aws_region}"
    ]

    only = ["vsphere-iso.ubuntu24"]
  }
}