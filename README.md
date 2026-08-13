# Air-Gapped IL4/IL5 Accredited Data Lakehouse (Zarf + UDS + Lula)

An enterprise-grade reference architecture for delivering an **Air-Gapped Data Lakehouse** (MinIO S3 + Apache Parquet + DuckDB/PostgreSQL) with continuous **DoD IL4 / IL5 Accreditation Artifact Generation** using **Zarf**, **UDS (Unicorn Delivery System)**, and **Lula (OSCAL Compliance-as-Code)**.

Provisioned on local hypervisor infrastructure via **Terraform** (`dmacvicar/libvirt` provider) using **HashiCorp Standard Module Structure** and `cloud-init`.

---

## 🏗️ Architecture Overview

```mermaid
flowchart TD
    subgraph Provisioning ["Phase 1: Infrastructure Provisioning"]
        TF[Terraform Module libvirt_vm] -->|cloud-init| VM[KVM Guest VM on T5600]
        VM --> K3S[K3s / Local K8s Cluster]
    end

    subgraph Packaging ["Phase 2: Zarf & UDS Air-Gapped Bundling"]
        APP[Python ETL + MinIO S3 + Postgres] --> ZARF[Zarf Package Creator]
        ZARF -->|zarf package create| TAR[zarf-package-datalakehouse.tar.zst]
        TAR --> UDS[UDS Bundle Orchestration]
    end

    subgraph Deployment ["Phase 3: Zero-Trust Cluster Deployment"]
        UDS -->|uds deploy| K3S
    end

    subgraph Accreditation ["Phase 4: Lula OSCAL IL4/IL5 Compliance"]
        K3S --> LULA[Lula Assessment Engine]
        LULA -->|lula evaluate| OSCAL[OSCAL Assessment JSON]
        OSCAL --> REPORT[Generated IL4/IL5 ATO Package / SAR Report]
    end
```

---

## 📚 Documentation Index

| File | Description |
| :--- | :--- |
| 📋 **[PLAN.md](PLAN.md)** | Step-by-step phased execution roadmap with explicit verification checkpoints at every phase. |
| 🛠️ **[DEVELOPMENT.md](DEVELOPMENT.md)** | Tool prerequisites, environment variable configuration, and developer workflow commands. |
| 📑 **[docs/adr/](docs/adr/)** | Architecture Decision Records capturing design choices, trade-offs, and rationale. |

---

## 🚀 Quick Start Summary

```bash
# 1. Inspect the Master Plan
cat PLAN.md

# 2. Provision Dev VM Infrastructure via Terraform
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply

# 3. Verify VM Connectivity & K8s Cluster
ssh brian@<vm-ip> 'kubectl get nodes'
```

For full setup instructions, follow **[DEVELOPMENT.md](DEVELOPMENT.md)**.
