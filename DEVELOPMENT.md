# Developer & Workflow Guide

This guide details the local workstation prerequisites, environment configuration, and verification commands required to build and run the **Zarf + UDS + Lula Data Lakehouse** project using HashiCorp Standard Module Structure.

---

## 🛠️ 1. Local Tooling Prerequisites

Ensure the following tools are installed on your host system:

* **Terraform** (`>= 1.5.0`): Infrastructure provisioning tool.
* **libvirt / QEMU / KVM**: Hypervisor daemon and client utilities (`virsh`, `virt-install`).
* **Zarf** (`>= 0.30.0`): Air-gapped packaging CLI tool.
* **UDS CLI** (`>= 0.10.0`): Defense Unicorns delivery stack bundler.
* **Lula** (`>= 0.8.0`): OSCAL continuous compliance evaluation CLI.
* **Python** (`3.10+`): For local data transformation scripts and compliance report parsing.

---

## 🔑 2. Environment Configuration

1. **Configure Hypervisor Access:**
   Ensure SSH key-based access to the hypervisor host is functional:
   ```bash
   ssh-copy-id brian@127.0.0.1
   ```

2. **Configure Terraform Dev Environment:**
   Navigate to the dev environment root module:
   ```bash
   cd terraform/environments/dev
   cp terraform.tfvars.example terraform.tfvars
   ```

---

## 🧪 3. Verification Commands

For each step in **[PLAN.md](PLAN.md)**, run the designated verification command before proceeding:

* **Verify Hypervisor State:**
  ```bash
  virsh list --all
  ```

* **Verify Cluster Status:**
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
  ```
