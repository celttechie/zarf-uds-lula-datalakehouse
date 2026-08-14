variable "sandbox_vm_name" {
  description = "Name of the nested sandbox hypervisor VM"
  type        = string
  default     = "datalakehouse-sandbox-node"
}

variable "sandbox_vm_ip" {
  description = "Assigned IP address of the nested sandbox VM (set in tfvars or known lease)"
  type        = string
  default     = "192.168.9.150"
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
