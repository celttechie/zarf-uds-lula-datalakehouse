output "public_ip" {
  description = "Public IPv4 address of the K3s Spot instance"
  value       = aws_spot_instance_request.k3s_spot_node.public_ip
}

output "private_ip" {
  description = "Private IPv4 address of the K3s Spot instance"
  value       = aws_spot_instance_request.k3s_spot_node.private_ip
}

output "instance_id" {
  description = "EC2 Instance ID of the provisioned Spot instance"
  value       = aws_spot_instance_request.k3s_spot_node.spot_instance_id
}

output "ssh_private_key" {
  description = "OpenSSH private key for connecting to the EC2 instance"
  value       = tls_private_key.k3s_ssh_key.private_key_openssh
  sensitive   = true
}

output "ssh_public_key" {
  description = "OpenSSH public key"
  value       = tls_private_key.k3s_ssh_key.public_key_openssh
}

output "ssh_command" {
  description = "SSH connection command using generated private key"
  value       = "ssh -i id_ed25519 -o StrictHostKeyChecking=accept-new ubuntu@${aws_spot_instance_request.k3s_spot_node.public_ip}"
}
