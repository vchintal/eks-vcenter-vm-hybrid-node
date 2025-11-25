terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18.0"
    }
    vsphere = {
      source  = "vmware/vsphere"
      version = "2.15.0"
    }
  }
}