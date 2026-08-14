# 6. Two-Stage Nested Sandbox Architecture & Deterministic SSH Host Keys

Date: 2026-08-13

## Status

Accepted

## Context

To mirror the production-grade homelab architecture (`homelab-terraform_k8s`), workloads and Kubernetes cluster nodes must NOT run directly on the physical hypervisor host (`192.168.9.110`). Furthermore, SSH connections to newly provisioned VMs must maintain strict security without disabling host key verification.

## Decision

1. **Two-Stage Nested Sandbox Architecture:**
   * **Stage 1 (`terraform/environments/01-nested-sandbox`):** Provisions a dedicated **Nested Hypervisor Sandbox VM** (`datalakehouse-sandbox-node`) on the physical hypervisor (`192.168.9.110`). The VM enables `/dev/kvm` via CPU `host-passthrough` and configures `libvirtd` and default storage pools.
   * **Stage 2 (`terraform/environments/02-k8s-cluster`):** Provisions K8s cluster and workload nodes **inside** the Stage 1 Sandbox VM hypervisor domain.
2. **Deterministic SSH Host Keys via Cloud-Init:**
   * Terraform generates ED25519 SSH host keys using `tls_private_key` resources.
   * Host keys are injected into Cloud-Init (`cloud_init.cfg`) under `ssh_keys:` (`ed25519_private` & `ed25519_public`).
   * Terraform populates a workspace-isolated `.terraform/known_hosts` file (`local_file`), guaranteeing strict SSH security without ignoring host key verification.

## Consequences

* Workloads are isolated inside the nested sandbox layer.
* Eliminates SSH man-in-the-middle risks and host key mismatch prompts.
