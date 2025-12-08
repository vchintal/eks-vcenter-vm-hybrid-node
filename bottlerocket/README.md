# Bottlerocket based EKS Hybrid Node for VMware vCenter
This folder contains a script that downloads the official Bottlerocket OVA for 
EKS Hybrid Nodes and uses it to create a VM template in VMware vCenter

## Prerequisites
- tuftool (use [intructions](https://anywhere.eks.amazonaws.com/docs/osmgmt/artifacts/#download-bottlerocket-node-images) 1 and 2 for installation)
- [govc](https://github.com/vmware/govmomi/releases) CLI binary installed
- Access to a VMWare vCenter server where you deploy the downloaded OVA as 
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
cd eks-vcenter-vm-hybrid-node/bottlerocket
```

### Prepare the variables file with values 

Update the file named [`hybrid-nodes.env`](../hybrid-nodes.env) in 
the parent directory by providing values for variables:
1. `eks_version` 
2. `bottlerocket_version`
3. Pertaining to your actual `vCenter` configuration.

The rest of the variables beyond the ones listed above are **NOT** mandatory 
for this exercise and can be left empty.

## Deploy
To download the Bottlerocket OVA file and make it as a template in vCenter, run 
the following command from the `bottlerocket` directory.

```sh 
./setup-bootlerocket-template.sh
```

## Verify 
After the script finished execution, log in to your vCenter server and verify 
that the VM template named `eks-hybrid-node-ubuntu24-template` has been created 
in the specified folder using `govc` CLI.


```sh
export GOVC_USERNAME="<<vsphere_user>>"
export GOVC_PASSWORD="<<vsphere_password>>"
export GOVC_INSECURE=true
export GOVC_URL="https://<<vsphere_server>>/sdk" 

govc find . -type m -name "eks-hybrid-node-bottlerocket-template"
```

You should see the path to the newly created VM template in the output.

```
/home/vm/Linux Templates/eks-hybrid-node-bottlerocket-template
```
