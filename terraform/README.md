# AWS Cloud Setup with or without Site-to-Site VPN

This portion of the repository sets up the following cloud resources that
are essential for provisioning EKS Hybrid Node.
- **VPC** with :
  - Both `public` and `private` subnets
  - Route propagation enabled via VPN Gateway (if used)
  - _Customer Gateway_ enabled when `enable_s2s_vpn = true`
- **EKS cluster** with :
  -  `Auto Mode` enabled
  -  Essential add-ons required for EKS Hybrid Node
  -  _Remote Network Config_ enabled with details about Node and Pod networks
    used on-premise
- **Site-to-Site VPN** (`enable_s2s_vpn = true`)
  - _VPN Gateway_ with static routes (no BGP)
  - Static route configured with the on-premise network CIDR
  
## Prerequisites

- Terraform v1.13.4+
- Access to a VMware vCenter server where you can deploy the generated ISO image.
  Following details need to be captured:
  * vCenter server `hostname`
  * vCenter server `username` of the user with sufficient privileges to create
     VMs and VM Templates
  * vCenter server `password`
  * vCenter server `datacenter` name
  * vCenter server `cluster` name
  * vCenter server `folder` name where the generated VM template would be stored
  * vCenter server `network` name
- EKS Hybrid Node ISO image is deployed to vCenter as a VM template
  ([instructions](./../packer/README.md)) using the Packer configuration files 
  in the `packer` directory. Use the [verification steps](./../packer/README.md#verify) provided.
- The file [default.auto.pkrvars.hcl](./../packer/default.auto.pkrvars.hcl) is 
fully populated with values for every listed variable


## Setup Hybrid Network Connectivity

### Deploy VPC 

At the command prompt, while in the `terraform` folder, run the following command
to deploy the VPC:

If you want the to setup Site-to-Site VPN as well with Terraform, run:

```sh 
terraform init
terraform apply \
    -var "customer_gateway_ip_address=XXX.XXX.XXX.XXX" \
    -var-file=./../packer/default.auto.pkrvars.hcl \
    -target=module.vpc \
    -target=module.vpn_gateway \
    --auto-approve
```

In the above command, `XXX.XXX.XXX.XXX` stands for the Public IP address of your
on-premises gateway.

If you DO NOT want the to setup Site-to-Site VPN with Terraform run:

```sh 
terraform init
terraform apply \
    -var-file=./../packer/default.auto.pkrvars.hcl \
    -var "enable_s2s_vpn=false" \
    -target=module.vpc \
    --auto-approve
```

### Connect Remote On-Premise Network to VPC

Before proceeding with setting up rest of the infrastructure including provisiong
EKS, we need to make sure that the On-Premise Network is connected to the VPC.

If using Site-to-Site VPN with the Terraform code, where variable 
`enable_s2s_vpn=true`, then after the **VPC** and the **VPN Gateway** have been 
created follow the instructions like the one shown 
[here](https://github.com/vchintal/aws-to-pfsense-s2s-vpn) to connect your 
remote network to the VPC.

> [!WARNING] 
> If using Direct Connect, the configuration to connect and setup the routing 
> correctly between the Remote On-Premise Network and the VPC is beyond the 
> scope of the this automation

## Deploy EKS Cluster and Hybrid Nodes

Once the VPC is connected to the Remote On-Premise Network, you can proceed to
deploy the EKS Cluster and Hybrid Nodes by running the following command:

If you setup Site-to-Site VPN with Terraform then run the following command:

```sh
terraform apply \
     -var "customer_gateway_ip_address=XXX.XXX.XXX.XXX" \
     -var-file=./../packer/default.auto.pkrvars.hcl \
     --auto-approve
```

else 

```sh
terraform apply \
    -var-file=./../packer/default.auto.pkrvars.hcl \
    -var "enable_s2s_vpn=false" \
    --auto-approve
```

## Verify

Once the Terraform run is complete, you can verify the EKS cluster and nodes
using the following commands:

```sh
# If default values are used for the setup:
aws eks --region us-west-2 update-kubeconfig --name eks-cluster-1

kubectl get nodes
```

You should see both the managed nodes and hybrid nodes in the output similar to
the output shown below.

```text
NAME                   STATUS   ROLES    AGE    VERSION
i-02c95468abb76eac0    Ready    <none>   14m    v1.34.0-eks-642f211
i-0d13ae5765693f612    Ready    <none>   14m    v1.34.0-eks-642f211
mi-04b284f89fdb00d39   Ready    <none>   110s   v1.34.1-eks-113cf36
mi-0b35ce7aa7993ecd8   Ready    <none>   110s   v1.34.1-eks-113cf36
mi-0b588aa2e34281dfc   Ready    <none>   110s   v1.34.1-eks-113cf36
mi-0e86dd674b3478d90   Ready    <none>   110s   v1.34.1-eks-113cf36
```

## Cleanup

To delete all the resources created by this Terraform configuration, run the
following command(s) from the `terraform` directory:

```sh
# If Site-to-Site VPN is used with Terraform:
terraform destroy \
    -var "customer_gateway_ip_address=XXX.XXX.XXX.XXX" \
    -var-file=./../packer/default.auto.pkrvars.hcl

# If Site-to-Site VPN is NOT used with Terraform:
terraform destroy \
    -var-file=./../packer/default.auto.pkrvars.hcl \
    -var "enable_s2s_vpn=false"
```
