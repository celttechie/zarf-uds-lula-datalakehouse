terraform {
  required_version = ">= 1.0.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
  }
}

module "dev_vm" {
  source = "../../modules/libvirt_vm"

  vm_name              = var.vm_name
  libvirt_user         = var.libvirt_user
  libvirt_host_ip      = var.libvirt_host_ip
  ssh_private_key_path = var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path
  ssh_known_hosts_path = var.ssh_known_hosts_path
  libvirt_network_name = var.libvirt_network_name
  vm_memory            = var.vm_memory
  vm_vcpu              = var.vm_vcpu
}
