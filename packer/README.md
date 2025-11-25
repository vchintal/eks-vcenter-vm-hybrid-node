# EKS Hybrid Node ISO for VMware vCenter

This directory contains Packer configuration files to build a custom ISO image 
for deploying EKS Hybrid worker nodes on vCenter. The 

## Prerequisites
- [Packer](https://www.packer.io/downloads) installed on your local machine.
- [govc](https://github.com/vmware/govmomi/releases) CLI binary installed

- Access to a VMWare vCenter server where you can deploy the generated ISO image. 
  Following details need to be captured:
  * vCenter server `hostname` 
  * vCenter server `username` of the user with sufficient privileges to create 
   VMs and VM Templates 
  * vCenter server `password`
  * vCenter server `datacenter` name
  * vCenter server `cluster` name
  * vCenter server `folder` name where the generated VM template would be stored
  * vCenter server `network` name

## Prepare

### Download the repo and initialize it
```sh
git clone https://github.com/vchintal/eks-vcenter-vm-hybrid-node
cd eks-vcenter-vm-hybrid-node/packer
```

### Prepare the variables file with values 

Update the file named [`default.auto.pkrvars.hcl`](default.auto.pkrvars.hcl) in 
the `packer` directory with the following content, providing values using your 
actual `vCenter` configuration:

```
iso_url            = "https://cofractal-ewr.mm.fcix.net/ubuntu-releases/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
iso_checksum       = "c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
vsphere_server     = 
vsphere_user       = 
vsphere_password   = 
vsphere_datacenter = 
vsphere_cluster    = 
vsphere_datastore  = 
vsphere_folder     = "Linux Templates"
vsphere_network    = 
vm_template_name   = "eks-hybrid-node-ubuntu24-template"
```

For Ubuntu ISO url, refer to the many [mirrors](https://launchpad.net/ubuntu/+archivemirrors) 
closest to your region. Also, if you are choosing any other version of the ISO, 
update the `iso_checksum` value as well with the corresponding checksum for the file.

## Deploy
To build the ISO image and deploy it to your vCenter server as a VM template, run 
the following command from the `packer` directory.

```sh 
# Optionally validate the configuration before running the build
packer validate -var-file=default.auto.pkrvars.hcl hybrid-nodes-template.pkr.hcl

packer build .
```

## Verify 
After the build process completes, log in to your vCenter server and verify 
that the VM template named `eks-hybrid-node-ubuntu24-template` has been created 
in the specified folder using `govc` CLI.


```sh
export GOVC_USERNAME="<<vsphere_user>>"
export GOVC_PASSWORD="<<vsphere_password>>"
export GOVC_INSECURE=true
export GOVC_URL="https://<<vsphere_server>>/sdk" 

govc find . -type m -name "eks-hybrid-node-ubuntu24-template"
```

You should see the path to the newly created VM template in the output.

```
/home/vm/Linux Templates/eks-hybrid-node-ubuntu24-template
```
