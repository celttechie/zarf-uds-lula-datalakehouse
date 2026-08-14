variable "sandbox_vm_name" {
  description = "Name of the nested sandbox hypervisor VM"
  type        = string
  default     = "datalakehouse-sandbox-node"
}

variable "libvirt_user" {
  description = "Username for physical hypervisor SSH access"
  type        = string
  default     = "bjarrett"
}

variable "libvirt_host_ip" {
  description = "IP address of physical hypervisor host"
  type        = string
  default     = "192.168.9.110"
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
  description = "Path to client SSH known_hosts file"
  type        = string
  default     = "~/.ssh/known_hosts"
}

variable "libvirt_network_name" {
  description = "Physical hypervisor network bridge name"
  type        = string
  default     = "host-bridge"
}

variable "vm_memory" {
  description = "RAM allocated to Sandbox VM in MB"
  type        = number
  default     = 16384
}

variable "vm_vcpu" {
  description = "vCPUs allocated to Sandbox VM"
  type        = number
  default     = 4
}

variable "disk_size_bytes" {
  description = "Disk size in bytes"
  type        = number
  default     = 53687091200 # 50 GB
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
