# 2. Infrastructure Provisioning via Terraform and libvirt

Date: 2026-08-13

## Status

Accepted

## Context

To run zero-trust Kubernetes clusters (Zarf/UDS) locally on the T5600 workstation, we require an automated mechanism to spin up guest virtual machines with nested virtualization support (`/dev/kvm` host-passthrough).

## Decision

We choose **Terraform** using the **`dmacvicar/libvirt`** provider and **`cloud-init`**, mirroring the established architecture in `homelab-terraform_k8s`.

### Rationale:
* **Declarative Control:** Infrastructure is defined as code (`main.tf`, `variables.tf`), making VM teardown and rebuild deterministic.
* **Cloud-Init Bootstrapping:** Automates base system package installation, SSH key injection, and K3s node setup on initial boot.
* **Hardware Passthrough:** Enables QEMU/KVM `host-passthrough` mode for optimal nested hypervisor performance.

## Consequences

* Requires `libvirt` daemon and `qemu-guest-agent` active on the host hypervisor.
* Local state files (`terraform.tfstate`) must be properly excluded from version control via `.gitignore`.
