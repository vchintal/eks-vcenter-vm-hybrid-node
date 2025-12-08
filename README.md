# EKS Hybrid Nodes on VMware vCenter

## EKS Hybrid Nodes 

Amazon EKS  Hybrid Nodes represent a revolutionary approach to hybrid cloud computing, extending your Amazon EKS clusters beyond AWS boundaries to run workloads on your own infrastructure while maintaining a single, unified AWS-managed control plane. This innovative solution bridges the gap between cloud-native operations and on-premises requirements.

### Key Advantages

- **Unified cluster management:** Single EKS control plane across AWS and on-premises environments
- **Seamless node integration:** Hybrid Nodes register as standard worker nodes with consistent scheduling
- **Data locality:** Execute workloads near on-premises data sources and legacy systems
- **Single control plane governance:** Centralized policy enforcement and security management
- **Cost optimization:** Leverage existing infrastructure while scaling to AWS as needed
- **Reduced latency:** Minimize network latency for real-time processing and on-premises interactions


## VMware vSphere and vCenter

VMware vSphere stands as the industry's most trusted and widely deployed virtualization platform, powering millions of workloads across enterprise datacenters worldwide. VMware vCenter Server serves as the centralized management hub, delivering comprehensive orchestration and advanced operational capabilities that have become the backbone of modern enterprise IT infrastructure.

### Enterprise-Grade Capabilities
- **Centralized management:** Unified control plane for monitoring and administration across virtual infrastructure
- **Advanced availability:** vMotion, High Availability, Distributed Resource Scheduler, and Fault Tolerance for continuous operations
- **Resource optimization:** Dynamic allocation and intelligent workload balancing across compute, storage, and networking
- **Enterprise ecosystem:** Mature tooling with extensive integrations and Fortune 500 adoption
- **Security and compliance:** VM encryption, secure boot, micro-segmentation, and audit logging
- **Hybrid cloud enablement:** Native integration for seamless on-premises and cloud management

## Perfect Match - Running vCenter VMs as EKS Hybrid Nodes

The convergence of VMware vCenter's enterprise virtualization capabilities with Amazon EKS Hybrid Nodes creates an optimal hybrid cloud architecture that maximizes both existing investments and future scalability. This strategic combination delivers unprecedented flexibility and operational efficiency for modern enterprise workloads.

### Strategic Benefits

- **Infrastructure investment protection:** Maximize return on investment for existing VMware vCenter deployments by leveraging current virtual machine infrastructure, skills, and operational processes while extending capabilities with cloud-native Kubernetes workloads
- **Proximity-based performance:** Execute latency-sensitive workloads directly on vCenter-managed virtual machines positioned near on-premises data sources, legacy applications, and business-critical systems
- **Elastic cloud bursting:** Seamlessly extend vCenter resources to AWS during peak demand periods, dynamically scaling Kubernetes workloads across both environments while maintaining operational consistency
- **Unified Kubernetes experience:** Leverage AWS managed EKS control plane across your hybrid infrastructure, whether workloads run on vCenter VMs or AWS native compute resources
- **Operational consistency:** Maintain familiar vCenter administration procedures, tooling, and governance frameworks while gaining cloud-native Kubernetes capabilities without operational disruption



## Solution Overview and Deployment

This comprehensive solution provides a end-to-end automation for deploying EKS Hybrid Nodes on VMware vCenter infrastructure. 

### Deployment Sequence

To successfully deploy this solution in your environment, follow the steps listed in sequence:

1. **[Bottlerocket based EKS Hybrid Node](bottlerocket/README.md)** - Use the official all-in-one Bottlerocket OVA with all necessary Kubernetes components, security configurations, and VMware tools pre-installed for EKS Hybrid Nodes.
2. **[Ubuntu based EKS Hybrid Node](packer/README.md)** - Build a customized, hardened virtual machine image optimized for EKS Hybrid Node operations using HashiCorp Packer. This step creates a golden image with all necessary Kubernetes components, security configurations, and VMware tools pre-installed. 
3. **[AWS Cloud Infrastructure Setup](terraform/README.md)** - Provision the required AWS infrastructure components including EKS cluster, networking, security groups, and optional Site-to-Site VPN connectivity using Terraform. This step establishes the cloud foundation and secure connectivity between your on-premises VMware environment and AWS.
