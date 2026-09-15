output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster API Server Endpoint"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_arn" {
  description = "ARN of the EKS Cluster"
  value       = module.eks_cluster.cluster_arn
}

output "update_kubeconfig_command" {
  description = "AWS CLI command to update local kubeconfig"
  value       = "aws eks update-kubeconfig --name ${module.eks_cluster.cluster_name} --region ${var.aws_region}"
}
