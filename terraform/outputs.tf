# # Uncomment the outputs below for the puspose of debugging and verification

# output "eks_cluster_name" {
#   description = "The name of the EKS cluster"
#   value       = module.eks.cluster_name
# }

# output "aws_region" {
#   description = "The AWS region where resources are deployed"
#   value       = var.aws_region
# }

# output "aws_ssm_activation_id" {
#   description = "The ID of the SSM Activation for hybrid nodes"
#   value       = aws_ssm_activation.this.id
# }

# output "aws_ssm_activation_code" {
#   description = "The code of the SSM Activation for hybrid nodes"
#   value       = aws_ssm_activation.this.activation_code
# }