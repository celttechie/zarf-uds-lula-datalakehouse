output "vm_name" {
  description = "Name of provisioned VM domain"
  value       = libvirt_domain.datalakehouse_node.name
}

output "vm_ip_addresses" {
  description = "IP addresses assigned to VM"
  value       = libvirt_domain.datalakehouse_node.network_interface[0].addresses
}
