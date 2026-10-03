# 16. Cluster-Aware Target Introspection in Tactical Mission Status Dashboard

Date: 2026-10-02

## Status

Accepted

## Context

The tactical edge mission status dashboard (`scripts/mission_status.sh` / `make mission-status`) provides mission operators and evaluators with a real-time console overview of node hardware topology, cluster health, running workloads, fused AWACS radar tracks, and continuous compliance posture.

Initially, Section 1 of `scripts/mission_status.sh` relied on host-local shell utilities (`uname -m`, `free -h`, `df -h`) and hardcoded specific hardware descriptions (e.g. `(ARMv8 64-Bit / Rockchip RK3588S - 8 Cores)` and `192.168.42.100/24`).

When executing the script from a developer workstation (e.g., an x86_64 host connected via `KUBECONFIG` to a remote ARM64 Orange Pi 5 Pro, or targeting a cloud EKS cluster), this produced confusing discrepancies—such as displaying the workstation's host architecture alongside hardcoded edge hardware labels, or showing an incorrect network address.

## Decision

We refactor `scripts/mission_status.sh` to implement **dynamic, cluster-aware node introspection**:

### 1. Dynamic Kubernetes Node Query
Section 1 dynamically queries the active target node through `kubectl get nodes -o json` to retrieve:
* **Target Node Name & Role**: (e.g., `orangepi5pro [control-plane,master]`)
* **Target CPU Architecture**: Extracted directly from `status.nodeInfo.architecture` (`arm64`, `amd64`).
* **Target OS & Kernel**: Extracted directly from `status.nodeInfo.osImage` and `status.nodeInfo.kernelVersion`.
* **Target Node Internal IP**: Discovered dynamically via `status.addresses[?(@.type=="InternalIP")].address`.
* **Target Kubelet & Container Runtime**: Discovered via `status.nodeInfo.kubeletVersion` and `status.nodeInfo.containerRuntimeVersion`.

### 2. Disconnected / Host Fallback
If `kubectl` is unreachable or the cluster is offline, the script cleanly falls back to querying the local host environment with clear labeling (`[LOCAL HOST FALLBACK]`), avoiding misleading hardcoded hardware labels.

## Consequences

### Positive
* **Truth in Advertising**: The dashboard always accurately displays the real target cluster node specifications regardless of whether the operator runs the command locally on the SBC or remotely from an x86_64 workstation.
* **Seamless Multi-Target Support**: Works identically when targeting the physical Orange Pi 5 Pro, the local Libvirt KVM sandbox VM, or an AWS EC2 Spot / EKS cluster.
* **Zero Hardcoded IPs or Architectures**: Fully portable across different subnets, maintenance links, and cloud VPC CIDRs.

### Negative / Trade-offs
* Requires `kubectl` and `jq` (or python JSON parsing fallback) when querying cluster state.

## References
* Kubernetes Node Status API: https://kubernetes.io/docs/reference/node/node-status/
* DoD Continuous Authorization to Operate (cATO) Architecture Guidelines
