# 12. Dual-Tier Ephemeral AWS Deployment Architecture (EC2 Spot + K3s and Managed EKS)

Date: 2026-09-04

## Status

Accepted

## Context

The **DoD IL4/IL5 Medallion Data Lakehouse** project uses Zarf and UDS (Unicorn Delivery System) to achieve air-gapped, zero-trust infrastructure portability across on-premise hypervisors (KVM / Libvirt) and commercial cloud providers. While local hypervisor sandboxing (Phases 1–6) provides a cost-free development foundation, validating cloud compatibility, cloud storage drivers (`gp3` / EBS CSI), and automated continuous accreditation (cATO) on Amazon Web Services (AWS) is essential for enterprise demonstrations and Authorizing Official (AO) reviews.

However, continuous cloud operation introduces significant cost and security risks:
1. **EKS Control Plane Overhead**: AWS charges a fixed $0.10/hour (~$73/month) per EKS cluster regardless of utilization, making persistent clusters cost-prohibitive for intermittent testing.
2. **Resource Sizing for UDS Core**: The workload requires 12–16 GB of RAM to run UDS Core (Istio service mesh, Pepr admission controller, Keycloak SSO) alongside MinIO, PostgreSQL, and PyArrow/DuckDB ETL jobs. Standard AWS Free Tier instances (`t2.micro` / `t3.micro` with 1 GB RAM) cannot support this stack.
3. **Infrastructure Portability**: Workload definitions (`zarf.yaml`, `uds-bundle.yaml`, Helm charts) must remain completely decoupled from underlying cloud infrastructure to honor the "build once, audit once, deploy anywhere" principle.

## Decision

We implement a **Dual-Tier Ephemeral AWS Deployment Strategy** managed via OpenTofu/Terraform, UDS configuration overlays, and strict FinOps guardrails:

### 1. Tier 1: Ultra-Low-Cost Dev/Test Sandbox (`03-aws-ec2-k3s`)
* **Target Architecture**: Single EC2 Spot Instance (`t3.xlarge`, 4 vCPU, 16 GB RAM, 50 GB gp3 root disk) running K3s with local-path storage.
* **Cost Profile**: **~$0.04 – $0.06 / hour** with **$0.00** control plane fee.
* **Deployment Velocity**: Bootstraps in under 90 seconds via `cloud-init` / `user_data`, pre-installing K3s, Zarf, and UDS binaries.
* **Use Case**: Fast inner-loop testing, network security group verification, and cost-free trial runs without incurring EKS charges.

### 2. Tier 2: Production-Fidelity ATO Demonstration (`04-aws-eks`)
* **Target Architecture**: Managed AWS EKS Cluster (Kubernetes 1.30+) with Spot-backed Managed Node Groups (`t3.xlarge`), AWS EBS CSI Driver addon (IRSA-enabled), and native `gp3` storage class.
* **Cost Profile**: **~$0.10 / hour** (EKS) + **~$0.05 / hour** (Spot nodes) $\approx$ **$0.30 – $0.50 per 2-hour validation run**.
* **Use Case**: Final end-to-end UDS bundle deployment, live `lula evaluate` compliance audits, and evidence generation for DoD IL5 ATO packages.

### 3. Environment Isolation & Configuration Overlays
* Workload definitions (`zarf.yaml`, `uds-bundle.yaml`) remain strictly unchanged.
* Environment differences are handled cleanly via runtime overlays:
  * `uds-config.yaml` -> Default local KVM / K3s (`storage_class: local-path`)
  * `uds-config-aws-k3s.yaml` -> EC2 K3s runtime overlay (`storage_class: local-path`, AWS public IP DNS)
  * `uds-config-aws-eks.yaml` -> Managed EKS runtime overlay (`storage_class: gp3`, AWS Ingress annotations)

### 4. FinOps as Code & Ephemeral Lifecycle Controls
* **Ephemeral By Design**: Environments are spun up on-demand and torn down immediately post-verification via Makefile targets:
  * `make aws-k3s-up` / `make aws-k3s-down`
  * `make aws-eks-up` / `make aws-eks-down`
* **Mandatory Resource Tagging**: All AWS resources carry deterministic billing tags (`Project: datalakehouse`, `Environment: dev-aws`, `AutoTeardown: true`, `Owner: celttechie`).
* **Deterministic Access**: Automated SSH key generation (`tls_private_key`) and kubeconfig retrieval helper script (`scripts/fetch_aws_kubeconfig.sh`).

## Consequences

### Positive
* **Budget Optimization**: Enables full AWS cloud validation for less than $1.00 total spend per testing cycle by leveraging Spot instances and rapid teardown.
* **Zero Workload Mutation**: Demonstrates pure Zarf/UDS portability—the exact same `.tar.zst` packages and OSCAL assessment manifests execute on bare-metal KVM and AWS EKS.
* **Defense Unicorns Alignment**: Adheres directly to Defense Unicorns platform patterns (IaC modularity, ephemeral sandboxes, declarative configuration overrides).
* **Enterprise CI/CD Integration**: Fully integrated into `make ci` and pre-flight OpenTofu validation.

### Negative / Trade-offs
* **Spot Interruption Risk**: Spot instances can theoretically be reclaimed by AWS, though interruption probability is negligible (<5%) during short 1–2 hour test windows.
* **AWS Credential Prerequisite**: Requires configured AWS IAM credentials (`aws configure`) on the local workstation before executing `terraform apply`.

## References
* AWS EKS Pricing & Spot Best Practices: https://aws.amazon.com/eks/pricing/
* Defense Unicorns Zarf Documentation: https://docs.zarf.dev/
* Defense Unicorns UDS Core: https://github.com/defenseunicorns/uds-core
* NIST SP 800-53 Rev 5: Security and Privacy Controls for Federal Information Systems
