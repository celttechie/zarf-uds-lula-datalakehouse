variable "cluster_node_name" {
  description = "Name of the workload node VM"
  type        = string
  default     = "datalakehouse-node-01"
}

variable "nested_hypervisor_user" {
  description = "Username for nested hypervisor VM SSH access"
  type        = string
  default     = "ubuntu"
}

variable "nested_hypervisor_ip" {
  description = "IP address of nested hypervisor VM"
  type        = string
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
  description = "Path to SSH known_hosts file"
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

variable "disk_size_bytes" {
  description = "Disk size in bytes"
  type        = number
  default     = 21474836480 # 20 GB
}

variable "host_private_key" {
  description = "ED25519 SSH host private key injected into cloud-init"
  type        = string
  default     = ""
}

variable "host_public_key" {
  description = "ED25519 SSH host public key injected into cloud-init"
  type        = string
  default     = ""
}
