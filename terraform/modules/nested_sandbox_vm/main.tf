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
  uri = "qemu+ssh://${var.libvirt_user}@${var.libvirt_host_ip}/system?keyfile=${pathexpand(var.ssh_private_key_path)}&known_hosts=${pathexpand(var.ssh_known_hosts_path)}"
}

# 1. Fetch official Ubuntu 22.04 LTS Cloud Image
resource "libvirt_volume" "ubuntu_base" {
  name   = "${var.sandbox_vm_name}-ubuntu-22.04-base.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

# 2. Create copy-on-write disk volume for the Nested Sandbox VM
resource "libvirt_volume" "sandbox_disk" {
  name           = "${var.sandbox_vm_name}-disk.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_base.id
  format         = "qcow2"
  size           = var.disk_size_bytes
}

# 3. Inject Cloud-Init configuration
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "${var.sandbox_vm_name}-commoninit.iso"
  pool = "default"
  user_data = templatefile("${path.module}/templates/cloud_init.cfg", {
    hostname         = var.sandbox_vm_name
    ssh_public_key   = file(var.ssh_public_key_path)
    host_private_key = var.host_private_key
    host_public_key  = var.host_public_key
  })
}

# 4. Define Nested Sandbox VM Domain
resource "libvirt_domain" "sandbox_node" {
  name   = var.sandbox_vm_name
  memory = var.vm_memory
  vcpu   = var.vm_vcpu

  # Expose physical host CPU virtualization extensions (/dev/kvm) into guest VM
  cpu {
    mode = "host-passthrough"
  }

  cloudinit  = libvirt_cloudinit_disk.commoninit.id
  qemu_agent = true

  network_interface {
    network_name   = var.libvirt_network_name
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.sandbox_disk.id
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
