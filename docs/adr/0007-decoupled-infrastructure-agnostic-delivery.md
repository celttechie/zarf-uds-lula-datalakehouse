# 7. Decoupled Infrastructure-Agnostic Air-Gapped Delivery

Date: 2026-08-13

## Status

Accepted

## Context

Users cloning this repository may have varying target environments—ranging from our local T5600 nested hypervisor setup to bare-metal servers, AWS EC2 instances, Proxmox VMs, or local KinD/K3s clusters.

## Decision

We strictly decouple **Infrastructure Provisioning (Terraform)** from **Package & Application Delivery (Zarf + UDS + Lula)**:

1. **Infrastructure Provisioning (Phase 1 - Optional):**
   * Provided for users who need to automate the creation of a local KVM VM hypervisor via Terraform (`01-nested-sandbox` & `02-k8s-cluster`).
2. **Bring Your Own Cluster / Server (Phases 2-6 - Core):**
   * Zarf, UDS, and Lula operate purely at the Kubernetes API layer.
   * Any user with an existing CNCF-compliant Kubernetes cluster (K3s, RKE2, EKS, AKS, KinD, bare-metal) can skip Phase 1 entirely, export their `KUBECONFIG`, and run `zarf package deploy` & `uds deploy`.

## Consequences

* Zero hardcoding of infrastructure assumptions inside Zarf packages, Helm charts, or Lula OSCAL policies.
* Maximum portability for air-gapped edge, cloud, and on-premises deployments.
