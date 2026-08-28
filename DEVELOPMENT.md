# Developer & Workflow Guide

This guide details the local workstation prerequisites, environment configuration, and verification commands required to build, bundle, deploy, and audit the **Zarf + UDS + Lula Data Lakehouse** project.

---

## 💡 Infrastructure Agnostic Design

Zarf, UDS, and Lula operate purely at the Kubernetes API level. This repository supports **two deployment workflows**:

1. **Option A (Automated Terraform Setup):** Use our included two-stage Terraform libvirt modules (`01-nested-sandbox` & `02-k8s-cluster`) to provision a fresh sandbox hypervisor VM and K3s cluster on a target host (`192.168.9.110`).
2. **Option B (Bring Your Own Server / Cluster):** Deploy directly to any existing physical server, cloud VM, or Kubernetes cluster (K3s, RKE2, EKS, KinD, Proxmox). Simply set `KUBECONFIG` and proceed to Phase 3 & Phase 4.

---

## 🛠️ 1. Local Tooling Prerequisites

Ensure the following tools are installed on your host system:

* **Zarf** (`>= 0.30.0`): Air-gapped packaging CLI tool.
* **UDS CLI** (`>= 0.10.0`): Defense Unicorns delivery stack bundler.
* **Lula** (`>= 0.8.0`): OSCAL continuous compliance evaluation CLI.
* **Python** (`3.10+`): For local data transformation scripts, verification tooling, and compliance report parsing.
* **Go** (`1.21+`): For compiling the compliance exporter CLI.
* **Terraform** (`>= 1.5.0` - *Optional for Option A*): Infrastructure provisioning tool.

---

## 🔑 2. Deployment Workflows

### Option A: Provisioning via Included Terraform Modules
```bash
# Stage 1: Nested Sandbox Hypervisor VM
cd terraform/environments/01-nested-sandbox
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# Stage 2: K8s Cluster Nodes inside Sandbox VM
cd ../02-k8s-cluster
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

### Option B: Deploying to Any Existing Server or K8s Cluster
```bash
# 1. Point to your target server / cluster
export KUBECONFIG=/path/to/target/kubeconfig

# 2. Build Zarf Air-Gapped Package (Phase 3)
make package
# or: zarf package create --confirm

# 3. Create & Deploy UDS Bundle (Phase 4)
make bundle-create
make bundle-deploy
# or: uds deploy uds-bundle-il5-data-lakehouse-bundle-amd64-0.4.0.tar.zst --confirm

# 4. Audit IL4/IL5 Compliance & Run Go Exporter (Phase 5)
make audit
```

---

## 🛡️ 3. Zero-Trust Service Mesh Security (Istio mTLS STRICT)

Phase 4 enforces zero-trust architecture across all deployed Medallion workloads:

* **Namespace-Wide mTLS STRICT (`k8s/mesh/peer-authentication.yaml`):** Enforces cryptographic mutual TLS identity and encryption across the `datalakehouse` namespace, rejecting plaintext communication.
* **Least-Privilege Authorization (`k8s/mesh/authorization-policy.yaml`):** Limits access to MinIO S3 (ports `9000`, `9001`) and PostgreSQL (port `5432`) strictly to authorized SPIFFE service account identities and ingress gateways.
* **Runtime Parameterization (`uds-config.yaml`):** Centralizes storage classes (`local-path`), domain routing (`datalake.local`), and DoD `IL5` baseline enforcement.

---

## 🧪 4. Verification & Testing Commands

For each step in **[PLAN.md](PLAN.md)**, run the designated verification command before proceeding:

* **Run Full Unit Test Suite (Phases 2-4):**
  ```bash
  make test
  # or: python3 -m unittest discover tests
  ```

* **Verify Phase 1 (Infrastructure & Sandbox):**
  ```bash
  make verify-phase1
  ```

* **Verify Phase 3 (Zarf Packaging & SBOM):**
  ```bash
  make verify-phase3
  ```

* **Verify Phase 4 (UDS Bundle & Istio Service Mesh):**
  ```bash
  make verify-phase4
  ```

* **Verify Target Cluster Status:**
  ```bash
  kubectl get nodes -o wide
  kubectl get pods -n datalakehouse
  kubectl get peerauthentication,authorizationpolicy -n datalakehouse
  ```

* **Verify Lula OSCAL Audit (Phase 5):**
  ```bash
  make audit
  ```
