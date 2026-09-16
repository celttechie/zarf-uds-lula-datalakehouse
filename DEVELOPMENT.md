# Developer & Workflow Guide

This guide details local workstation prerequisites, cloud authentication, environment configuration, and verification commands required to build, bundle, deploy, and audit the **Zarf + UDS + Lula Data Lakehouse** project.

---

## 💡 Multi-Target Infrastructure Design

Zarf, UDS, and Lula operate purely at the Kubernetes API level. This repository supports **four deployment targets**:

1. **Option A (Local KVM Sandbox VM):** Automated two-tier libvirt/KVM nested hypervisor sandbox (`01-nested-sandbox` & `02-k8s-cluster`) on a local or remote hypervisor host server.
2. **Option B (AWS EC2 Spot K3s):** Ephemeral single-node K3s cluster on an AWS EC2 Spot instance (`c6a.xlarge` / `t3.xlarge`) costing ~$0.04/hr with zero control-plane fee (`03-aws-ec2-k3s`).
3. **Option C (AWS Managed EKS):** Production-fidelity AWS EKS cluster (Kubernetes 1.30+) with Amazon Linux 2023 (`AL2023_x86_64_STANDARD`) managed node group and automated EBS CSI `gp3` storage class provisioning (`04-aws-eks`).
4. **Option D (Bring Your Own Cluster):** Deploy directly to any existing physical server, cloud VM, or Kubernetes cluster (KinD, RKE2, EKS, GKE, AKS, bare-metal). Simply set `KUBECONFIG` and proceed to packaging and deployment.

---

## 🛠️ 1. Workstation Tooling Prerequisites

Ensure the following tools are installed on your workstation:

* **Python** (`>= 3.10`): Required for Lakehouse ETL pipelines, test suites, and zero-dependency compliance evaluators.
* **OpenTofu / Terraform** (`>= 1.5.0`): Infrastructure provisioning for Options A, B, and C.
* **AWS CLI** (`>= 2.0` - *Required for Options B & C*): Configured with valid AWS credentials (`aws configure`).
* **kubectl** (`>= 1.28.0`): Kubernetes cluster management CLI.
* **Zarf** (`>= 0.30.0`): Air-gapped packaging CLI tool.
* **UDS CLI** (`>= 0.10.0`): Defense Unicorns delivery stack bundler.
* **Lula** (`>= 0.8.0` - *Optional*): OSCAL continuous compliance evaluation CLI (native Python fallback included).
* **Go** (`>= 1.21` - *Optional*): For compiling the compliance exporter binary (native Python fallback included).

### 🩺 Run Pre-Flight Diagnostics
Run `make doctor` before provisioning to inspect your local toolchain, AWS authentication, local Zarf cache, and declarative schema parity across files:

```bash
make doctor
# or: python3 scripts/doctor.py
```

---

## 🔑 2. Deployment Workflows

### Option A: Local KVM Sandbox VM via Libvirt
```bash
# Provision Stage 1 Layer 1 Nested Sandbox VM
make dev-sandbox

# Provision Stage 2 K8s Cluster Node inside Sandbox VM
make dev-cluster

# Deploy UDS Bundle
make bundle-deploy

# Tear down all local infrastructure
make dev-destroy-all
```

---

### Option B: Ephemeral AWS EC2 Spot + K3s Sandbox
Ideal for cost-effective CI/CD testing and cloud verification (~$0.04/hr).

```bash
# 1. Provision EC2 Spot instance and automatically fetch kubeconfig
make aws-k3s-up

# 2. Deploy UDS Bundle with AWS K3s runtime overlay
make bundle-deploy-aws-k3s

# 3. Execute IL4/IL5 Compliance Audit
make audit

# 4. Destroy EC2 instance immediately to eliminate spend
make aws-k3s-down
```

---

### Option C: Production-Fidelity AWS Managed EKS
Ideal for testing AWS EBS CSI driver integration, IAM roles for service accounts, and enterprise compliance.

```bash
# 1. Provision Managed EKS Cluster (1.30+) & configure gp3 storage class
make aws-eks-up

# 2. Deploy UDS Bundle with AWS EKS gp3 storage class overlay
make bundle-deploy-aws-eks

# 3. Execute IL4/IL5 Compliance Audit
make audit

# 4. Destroy Managed EKS cluster immediately to eliminate control plane fees
make aws-eks-down
```

---

### Option D: Deploy to Any Existing Server or Cluster
```bash
# 1. Point to your target server / cluster
export KUBECONFIG=/path/to/target/kubeconfig

# 2. Build Zarf Air-Gapped Package (Phase 3)
make package
# Generates: zarf-package-il5-data-lakehouse-amd64-0.3.0.tar.zst (with Syft SBOMs)

# 3. Initialize Zarf Internal Registry in Target Cluster (if not yet initialized)
make zarf-init

# 4. Deploy Zarf Package directly or via UDS Bundle
make zarf-deploy
# or:
make bundle-create
make bundle-deploy

# 5. Evaluate DoD IL4/IL5 Compliance (Phase 5)
make audit
```

---

## ⚙️ 3. Runtime Configuration Overlays

The deployment uses targeted UDS configuration overlays depending on the infrastructure environment:

* **`uds-config.yaml` (Default / Local KVM):** Configures `local-path` storage class and local mesh routing.
* **`uds-config-aws-k3s.yaml` (AWS EC2 K3s):** Parameterized for EC2 K3s single-node sandbox with `local-path` storage.
* **`uds-config-aws-eks.yaml` (AWS Managed EKS):** Overrides storage class to AWS EBS `gp3` with dynamic volume expansion enabled.

---

## 🛡️ 4. Zero-Trust Service Mesh Security (Istio mTLS STRICT)

Phase 4 enforces zero-trust architecture across all deployed Medallion workloads:

* **Namespace-Wide mTLS STRICT (`k8s/mesh/peer-authentication.yaml`):** Enforces cryptographic mutual TLS identity and encryption across the `datalakehouse` namespace, rejecting plaintext communication.
* **Least-Privilege Authorization (`k8s/mesh/authorization-policy.yaml`):** Limits access to MinIO S3 (ports `9000`, `9001`) and PostgreSQL (port `5432`) strictly to authorized SPIFFE service account identities and ingress gateways.
* **DoD IL5 Compliance Baseline:** Evaluates container security context (non-root execution, read-only root filesystems, drop all capabilities) and cryptographic boundary protections.

---

## 🧪 5. Verification & Testing Commands

* **Pre-Flight Diagnostics:**
  ```bash
  make doctor
  ```

* **Full Unit Test Suite (28 automated tests):**
  ```bash
  make test
  ```

* **Continuous Compliance Audit (Lula / Python Fallback):**
  ```bash
  make audit
  ```

* **Generate DoD IL5 ATO Package (SSP, SAR, ConMon, POA&M):**
  ```bash
  make ato-package
  ```

* **Automated Phase Verification Gates:**
  ```bash
  make verify-phase1   # Verify local KVM sandbox VM
  make verify-phase3   # Verify Zarf package & Syft SBOMs
  make verify-phase4   # Verify UDS bundle & Istio service mesh
  make verify-phase5   # Verify Lula OSCAL evaluation
  make verify-phase6   # Verify ATO artifact generation
  ```
