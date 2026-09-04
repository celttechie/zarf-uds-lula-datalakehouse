output "public_ip" {
  description = "Public IPv4 address of the K3s Spot instance"
  value       = module.k3s_sandbox.public_ip
}

output "private_ip" {
  description = "Private IPv4 address of the K3s Spot instance"
  value       = module.k3s_sandbox.private_ip
}

output "instance_id" {
  description = "EC2 Spot instance ID"
  value       = module.k3s_sandbox.instance_id
}

output "ssh_command" {
  description = "SSH connection command using generated private key"
  value       = "ssh -i ${path.module}/.terraform/id_ed25519 -o StrictHostKeyChecking=accept-new ubuntu@${module.k3s_sandbox.public_ip}"
}

output "kubeconfig_fetch_command" {
  description = "Command to retrieve remote K3s kubeconfig to your local machine"
  value       = "ssh -i ${path.module}/.terraform/id_ed25519 -o StrictHostKeyChecking=accept-new ubuntu@${module.k3s_sandbox.public_ip} 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed 's/127.0.0.1/${module.k3s_sandbox.public_ip}/g' > ${path.module}/.terraform/kubeconfig.yaml"
}
