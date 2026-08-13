output "vm_name" {
  description = "Name of provisioned VM domain"
  value       = module.dev_vm.vm_name
}

output "vm_ip_addresses" {
  description = "IP addresses assigned to VM"
  value       = module.dev_vm.vm_ip_addresses
}
