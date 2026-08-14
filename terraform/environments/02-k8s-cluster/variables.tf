variable "cluster_node_name" {
  description = "Name of the workload cluster node"
  type        = string
  default     = "datalakehouse-k8s-node-01"
}

variable "cluster_node_ip" {
  description = "Expected IP of the workload cluster node"
  type        = string
  default     = "192.168.122.100"
}

variable "nested_hypervisor_user" {
  description = "Username for nested hypervisor VM SSH access"
  type        = string
  default     = "ubuntu"
}

variable "nested_hypervisor_ip" {
  description = "IP address of nested hypervisor VM (Layer 1 Sandbox VM IP)"
  type        = string
  default     = "192.168.9.150"
}

variable "ssh_private_key_path" {
  description = "Path to client SSH private key"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "ssh_public_key_path" {
  description = "Path to client SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_known_hosts_path" {
  description = "Local path to the SSH known_hosts file for server host key verification"
  type        = string
  default     = "~/.ssh/known_hosts"
}

variable "vm_memory" {
  description = "RAM allocated to cluster node in MB"
  type        = number
  default     = 8192
}

variable "vm_vcpu" {
  description = "vCPUs allocated to cluster node"
  type        = number
  default     = 2
}
