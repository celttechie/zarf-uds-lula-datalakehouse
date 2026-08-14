output "vm_name" {
  description = "Name of provisioned Cluster Node VM domain"
  value       = module.k8s_cluster_node.vm_name
}

output "vm_ip_addresses" {
  description = "IP addresses assigned to Cluster Node VM"
  value       = module.k8s_cluster_node.vm_ip_addresses
}

output "cluster_node_public_key" {
  description = "Deterministic ED25519 public host key injected into Cluster Node VM"
  value       = tls_private_key.cluster_node_host_key.public_key_openssh
}
