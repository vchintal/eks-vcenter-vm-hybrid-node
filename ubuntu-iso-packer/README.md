# Ubuntu ISO based EKS Hybrid Node for VMware vCenter
This folder contains Packer configuration files to build a custom Ubuntu-based 
ISO image that is deployed as a VM template for creating EKS Hybrid worker nodes
 on vCenter. 

## Prerequisites
- [Packer](https://www.packer.io/downloads) installed on your local machine.
- [govc](https://github.com/vmware/govmomi/releases) CLI binary installed

- Access to a VMWare vCenter server where you deploy the generated ISO image as 
  a VM template. Following information is required:
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
cd eks-vcenter-vm-hybrid-node/ubuntu-iso-packer
```

### Prepare the variables file with values 

Update the file named [`hybrid-nodes.env`](../hybrid-nodes.env) in 
the parent directory by:

1. Providing values for Ubuntu ISO url and checksum. For Ubuntu ISO url, 
   refer to the many [mirrors](https://launchpad.net/ubuntu/+archivemirrors) 
   closest to your region. Also, if you are choosing any other version of the ISO than what is provided to you, update the corresponding `iso_checksum` 
   for the chosen file.
2. Providing updated values reflecting your actual `vCenter` configuration.

The rest of the variables beyond `Packer` and `vCenter` settings are **NOT** 
mandatory for this exercise and can be left empty.

## Deploy
To build the ISO image and deploy it to your vCenter server as a VM template, run 
the following command from the `packer` directory.

```sh 
# Optionally validate the configuration before running the build
packer validate -var-file=default.auto.pkrvars.hcl hybrid-nodes-template.pkr.hcl

packer build .
```

> [!NOTE]
> - The file `default.auto.pkrvars.hcl` is a symbolic link to `hybrid-nodes.env`
> file 
> - Since the file has other variables as well, when `packer validate` runs, it 
> might issue warnings that those variables do not exist. These can be safely 
> ignored.

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
