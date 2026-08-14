# Developer & Workflow Guide

This guide details the local workstation prerequisites, environment configuration, and verification commands required to build and run the **Zarf + UDS + Lula Data Lakehouse** project.

---

## 💡 Infrastructure Agnostic Design

Zarf, UDS, and Lula operate purely at the Kubernetes API level. This repository supports **two deployment workflows**:

1. **Option A (Automated Terraform Setup):** Use our included two-stage Terraform libvirt modules (`01-nested-sandbox` & `02-k8s-cluster`) to provision a fresh sandbox hypervisor VM and K3s cluster on a target host (`192.168.9.110`).
2. **Option B (Bring Your Own Server / Cluster):** Deploy directly to any existing physical server, cloud VM, or Kubernetes cluster (K3s, RKE2, EKS, KinD, Proxmox). Simply set `KUBECONFIG` and proceed to Phase 3.

---

## 🛠️ 1. Local Tooling Prerequisites

Ensure the following tools are installed on your host system:

* **Zarf** (`>= 0.30.0`): Air-gapped packaging CLI tool.
* **UDS CLI** (`>= 0.10.0`): Defense Unicorns delivery stack bundler.
* **Lula** (`>= 0.8.0`): OSCAL continuous compliance evaluation CLI.
* **Python** (`3.10+`): For local data transformation scripts and compliance report parsing.
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

# 2. Build Zarf Air-Gapped Package
make package

# 3. Deploy UDS Bundle
make deploy

# 4. Audit IL4/IL5 Compliance & Run Go Exporter
make audit
```

---

## 🧪 3. Verification Commands

For each step in **[PLAN.md](PLAN.md)**, run the designated verification command before proceeding:

* **Verify Target Cluster Status:**
  ```bash
  kubectl get nodes -o wide
  kubectl get pods -A
  ```

* **Verify Zarf Package:**
  ```bash
  zarf package inspect zarf-package-datalakehouse-amd64-0.1.0.tar.zst
  ```

* **Verify Lula OSCAL Audit:**
  ```bash
  lula evaluate -f oscal-il5.yaml -o il5-results.json
  ./bin/compliance_exporter il5-results.json
  ```
