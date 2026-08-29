terraform {
  required_version = ">= 1.0.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

# Deterministic SSH Host Key for Stage 1 Nested Sandbox VM
resource "tls_private_key" "sandbox_host_key" {
  algorithm = "ED25519"
}

# Workspace-isolated known_hosts file containing deterministic public host key
resource "local_file" "stage1_known_hosts" {
  filename        = "${path.module}/.terraform/known_hosts"
  file_permission = "0600"
  content         = "${module.nested_sandbox.vm_ip_addresses[0]} ${trimspace(tls_private_key.sandbox_host_key.public_key_openssh)}\n"
}

module "nested_sandbox" {
  source = "../../modules/nested_sandbox_vm"

  sandbox_vm_name      = var.sandbox_vm_name
  libvirt_user         = var.libvirt_user
  libvirt_host_ip      = var.libvirt_host_ip
  ssh_private_key_path = var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path
  ssh_known_hosts_path = var.ssh_known_hosts_path
  libvirt_network_name = var.libvirt_network_name
  vm_memory            = var.vm_memory
  vm_vcpu              = var.vm_vcpu

  host_private_key = tls_private_key.sandbox_host_key.private_key_openssh
  host_public_key  = tls_private_key.sandbox_host_key.public_key_openssh
}
