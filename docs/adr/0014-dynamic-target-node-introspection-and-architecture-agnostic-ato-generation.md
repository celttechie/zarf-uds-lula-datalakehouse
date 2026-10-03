# 14. Dynamic Target Node Introspection and Architecture-Agnostic ATO Artifact Generation

Date: 2026-10-02

## Status

Accepted

## Context

The System Security Plan (SSP) and DoD IL5 Authorization to Operate (ATO) documentation package in `docs/accreditation/` must accurately document the system's authorization boundary, hardware inventory, and infrastructure environment.

Initially, `scripts/generate_ato_package.py` contained hardcoded hardware specifications (such as a single bare-metal Dell Precision T5600 workstation). However, the platform supports multiple deployment substrates:
1. **Bare-Metal Tactical Edge SBCs**: Disconnected ARM64 single-board computers (e.g., Orange Pi 5 Pro / Rockchip RK3588S, Raspberry Pi 5).
2. **Local Hypervisor Sandboxes**: Two-tier Libvirt/KVM nested virtualization environments.
3. **AWS Cloud Substrates**: Ephemeral EC2 Spot K3s nodes (`c6a.xlarge` / `t3.xlarge`) and AWS Managed EKS clusters.
4. **External / Bring Your Own Cluster**: Any pre-existing Kubernetes cluster (RKE2, K3s, OpenShift, bare-metal).

Hardcoding a specific workstation or CPU architecture in the ATO package generator created brittle documentation that became invalid whenever switching target environments.

## Decision

We update the automated ATO generator (`scripts/generate_ato_package.py`) to employ **dynamic target node introspection** with a structured **architecture-agnostic fallback**:

### 1. Live Kubernetes Cluster Introspection
When `kubectl` is available and connected to a live target cluster, the generator queries `kubectl get nodes -o json` to dynamically extract:
* **Active Node Name & Roles**: (e.g., `orangepi5pro [control-plane,master]`)
* **Node CPU Architecture**: (e.g., `arm64`, `amd64`)
* **Operating System & Kernel**: (e.g., `Armbian 26.11 (resolute) | Linux 6.1.172`)
* **Kubelet & Container Runtime**: (e.g., `v1.30.4+k3s1 | containerd://1.7.20-k3s1`)

The generated SSP's *Hardware & Infrastructure Inventory* section dynamically embeds this discovered live node topology.

### 2. Multi-Target Baseline Support Matrix (Offline Fallback)
If the generator runs offline or without an active cluster connection, rather than hardcoding a single machine, the SSP generates an **Architecture-Agnostic Multi-Target Infrastructure Support Matrix** documenting the supported baseline execution profiles:
* **Tactical Edge SBC Baseline**: ARM64 / ARMv8 64-bit single-board computers (RK3588S / BCM2712).
* **Local Hypervisor Baseline**: x86_64 Libvirt/KVM nested virtualization sandboxes.
* **Cloud Infrastructure Baseline**: AWS EC2 Spot K3s and AWS Managed EKS (gp3 EBS CSI).

### 3. Updated Verification & ADR Index
* Updated [README.md](../../README.md) ADR table to index ADR 0014.
* Updated [DEVELOPMENT.md](../../DEVELOPMENT.md) and Phase 6 unit tests in [tests/test_ato_package.py](../../tests/test_ato_package.py) to validate dynamic node discovery.

## Consequences

### Positive
* **Accuracy Across Environments**: The SSP accurately reflects whichever node or cluster is currently active (e.g. Orange Pi 5 Pro vs T5600 vs AWS EKS).
* **Zero Target Locking**: Switching from edge ARM64 devices to cloud or local KVM hypervisors immediately generates accurate accreditation documentation with zero code changes.
* **Clean Offline Experience**: Local CI/CD pipelines without cluster access produce a comprehensive multi-target architectural baseline.

### Negative / Trade-offs
* Requires `kubectl` execution capability during live doc generation, handled via automated fallback if unavailable.

## References
* NIST SP 800-53 Rev 5: System and Services Acquisition (SA-4), Configuration Management (CM-8)
* DoD Continuous Authorization to Operate (cATO) Architecture Guidelines
