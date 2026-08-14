output "vm_name" {
  description = "Name of provisioned Sandbox VM domain"
  value       = module.nested_sandbox.vm_name
}

output "vm_ip_addresses" {
  description = "IP addresses assigned to Sandbox VM"
  value       = module.nested_sandbox.vm_ip_addresses
}

output "sandbox_host_public_key" {
  description = "Deterministic ED25519 public host key injected into Sandbox VM"
  value       = tls_private_key.sandbox_host_key.public_key_openssh
}
