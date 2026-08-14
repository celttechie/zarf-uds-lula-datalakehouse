terraform {
  required_version = ">= 1.0.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://${var.nested_hypervisor_user}@${var.nested_hypervisor_ip}/system?keyfile=${pathexpand(var.ssh_private_key_path)}&known_hosts=${pathexpand(var.ssh_known_hosts_path)}"
}

# 1. Base Ubuntu 22.04 LTS Cloud Image stored in Nested Sandbox pool
resource "libvirt_volume" "ubuntu_base" {
  name   = "${var.cluster_node_name}-ubuntu-22.04-base.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

# 2. Cluster Node Disk Volume
resource "libvirt_volume" "node_disk" {
  name           = "${var.cluster_node_name}-disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_base.id
  format         = "qcow2"
  size           = var.disk_size_bytes
}

# 3. Cloud-Init Disk for Cluster Node
resource "libvirt_cloudinit_disk" "node_init" {
  name = "${var.cluster_node_name}-init.iso"
  pool = "default"
  user_data = templatefile("${path.module}/templates/cloud_init.cfg", {
    hostname         = var.cluster_node_name
    ssh_public_key   = file(var.ssh_public_key_path)
    host_private_key = var.host_private_key
    host_public_key  = var.host_public_key
  })
}

# 4. Cluster Node VM Domain running inside Nested Sandbox Hypervisor
resource "libvirt_domain" "cluster_node" {
  name       = var.cluster_node_name
  memory     = var.vm_memory
  vcpu       = var.vm_vcpu
  qemu_agent = true

  cloudinit = libvirt_cloudinit_disk.node_init.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.node_disk.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
