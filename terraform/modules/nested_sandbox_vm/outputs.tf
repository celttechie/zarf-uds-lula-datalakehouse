output "vm_name" {
  description = "Name of provisioned Nested Sandbox VM domain"
  value       = libvirt_domain.sandbox_node.name
}

output "vm_ip_addresses" {
  description = "IP addresses assigned to Nested Sandbox VM"
  value       = libvirt_domain.sandbox_node.network_interface[0].addresses
}
