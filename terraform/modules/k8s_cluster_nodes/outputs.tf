output "vm_name" {
  description = "Name of provisioned Cluster Node VM domain"
  value       = libvirt_domain.cluster_node.name
}

output "vm_ip_addresses" {
  description = "IP addresses assigned to Cluster Node VM"
  value       = libvirt_domain.cluster_node.network_interface[0].addresses
}
