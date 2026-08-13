variable "vm_name" {
  description = "Name of the virtual machine domain"
  type        = string
  default     = "datalakehouse-node"
}

variable "libvirt_user" {
  description = "Username for hypervisor SSH access"
  type        = string
}

variable "libvirt_host_ip" {
  description = "IP address or hostname of hypervisor server"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
}

variable "ssh_known_hosts_path" {
  description = "Path to known hosts file"
  type        = string
}

variable "libvirt_network_name" {
  description = "Libvirt network name"
  type        = string
  default     = "default"
}

variable "vm_memory" {
  description = "RAM allocated to VM in MB"
  type        = number
  default     = 16384
}

variable "vm_vcpu" {
  description = "vCPUs allocated to VM"
  type        = number
  default     = 4
}

variable "disk_size_bytes" {
  description = "Disk size in bytes"
  type        = number
  default     = 53687091200 # 50 GB
}
