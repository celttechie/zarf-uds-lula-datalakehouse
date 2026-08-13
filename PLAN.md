# Master Execution Plan: Air-Gapped IL4/IL5 Data Lakehouse (Zarf + UDS + Lula)

This document outlines the **6-Phase Implementation Plan** for building, deploying, and auditing an air-gapped Data Lakehouse and automated IL4/IL5 accreditation engine.

> ⚠️ **Verification Gate Requirement:** After completing each phase, you MUST execute the **Gate Verification Commands** and confirm green status before advancing to the next phase.

---

## 📅 Phase Summary Roadmap

```
[Phase 1: Terraform VM Provisioning] ➔ [Phase 2: Data Lakehouse & ETL Core] ➔ [Phase 3: Zarf Air-Gapped Package] 
                                                                                        │
[Phase 6: IL4/IL5 ATO Artifact Package]  [Phase 5: Lula OSCAL Audit Engine]  [Phase 4: UDS Bundle & K8s Deploy]
```

---

## 🚩 Phase 1: Infrastructure Provisioning via Terraform (`libvirt` / KVM)

### Objective
Automate the deployment of a dedicated development VM (`datalakehouse-node`) on the local T5600 hypervisor host using Terraform and `cloud-init`.

### Tasks
- [ ] Create `terraform/environments/01-dev-vm/main.tf` using `dmacvicar/libvirt` provider.
- [ ] Configure `cloud_init.cfg` template to inject SSH keys, hostname, and K3s prerequisites.
- [ ] Run `terraform init` and `terraform apply`.

### 🔍 Gate Verification Commands (Phase 1)
```bash
# 1. Verify VM Domain is running on Hypervisor
virsh list --all | grep datalakehouse-node

# 2. Test SSH Access & QEMU Agent responsiveness
ssh brian@<vm-ip> 'hostname && uname -a'

# 3. Verify K3s cluster node status
ssh brian@<vm-ip> 'kubectl get nodes -o wide'
```
**Success Criteria:** VM state is `running`, SSH connection succeeds without password, and `kubectl get nodes` returns `Ready`.

---

## 🚩 Phase 2: Data Lakehouse & ETL Application Core

### Objective
Build the Data Lakehouse application components (MinIO S3 for unstructured data, Apache Parquet converter, DuckDB/PostgreSQL for warehousing analytics).

### Tasks
- [ ] Create `src/lakehouse_etl.py` script handling raw unstructured JSON/logs -> Bronze S3 bucket.
- [ ] Implement PyArrow / DuckDB transformation to columnar Parquet -> Silver S3 bucket.
- [ ] Implement Gold layer analytical summary table inside PostgreSQL.
- [ ] Create Kubernetes manifests in `k8s/` (`minio.yaml`, `postgres.yaml`, `etl-job.yaml`).

### 🔍 Gate Verification Commands (Phase 2)
```bash
# 1. Run local test of Python Lakehouse ETL pipeline
python3 src/lakehouse_etl.py

# 2. Verify Parquet object creation & S3 bucket contents
python3 -c "import boto3; s3=boto3.client('s3', endpoint_url='http://localhost:9000', aws_access_key_id='minioadmin', aws_secret_access_key='minioadmin'); print(s3.list_objects(Bucket='processed-warehouse-lake'))"

# 3. Query PostgreSQL Gold Data Warehouse table
python3 -c "import duckdb; print(duckdb.query('SELECT * FROM summary_df').df())"
```
**Success Criteria:** ETL script completes without error, Parquet files are generated in S3, and SQL warehouse queries return aggregate results.

---

## 🚩 Phase 3: Zarf Air-Gapped Packaging

### Objective
Bundle all container images, manifests, and scripts into a single immutable `.tar.zst` Zarf package capable of deploying into zero-trust, disconnected environments.

### Tasks
- [ ] Draft `zarf.yaml` with components for `minio-storage`, `postgres-warehouse`, and `etl-engine`.
- [ ] Include all required OCI container images (`minio/minio`, `postgres:15-alpine`, `python:3.11-slim`).
- [ ] Run `zarf package create --confirm`.

### 3. Gate Verification Commands (Phase 3)
```bash
# 1. Inspect generated Zarf package metadata & SBOM
zarf package inspect zarf-package-il5-data-lakehouse-amd64-0.2.0.tar.zst

# 2. Validate images and components in Zarf package
zarf package inspect --sbom zarf-package-il5-data-lakehouse-amd64-0.2.0.tar.zst
```
**Success Criteria:** `zarf package create` succeeds, generating a valid `.tar.zst` package with complete Software Bill of Materials (SBOM).

---

## 🚩 Phase 4: UDS Bundle Orchestration & Cluster Deployment

### Objective
Orchestrate the Zarf package using **UDS (Unicorn Delivery System)** alongside UDS Core (Istio mTLS service mesh, Keycloak SSO, and Pepr policies).

### Tasks
- [ ] Create `uds-bundle.yaml` referencing the local Zarf package.
- [ ] Initialize Zarf on target VM cluster (`zarf init`).
- [ ] Deploy UDS bundle (`uds deploy`).

### 🔍 Gate Verification Commands (Phase 4)
```bash
# 1. Check all deployed pods in cluster
kubectl get pods -n default

# 2. Verify Istio mTLS Policy Enforcement
kubectl get peerauthentication -A

# 3. Test API connectivity through Istio Service Mesh
curl -k https://minio.datalake.local/minio/health/live
```
**Success Criteria:** All K8s pods transition to `Running` state, Istio mTLS is enforced in `STRICT` mode, and service endpoints respond cleanly.

---

## 🚩 Phase 5: Lula OSCAL Continuous Compliance Audit

### Objective
Define DoD IL4/IL5 security controls in OSCAL format (`oscal-il5.yaml`) and run continuous compliance validation against the live cluster state using Lula.

### Tasks
- [ ] Write `oscal-il5.yaml` covering NIST SC-13 (Data-at-Rest Protection) and SC-8 (Data-in-Transit Protection).
- [ ] Embed Rego validation policy rules targeting K8s Pod `securityContext` and Istio `PeerAuthentication`.
- [ ] Run `lula evaluate -f oscal-il5.yaml -o il5-results.json`.

### 🔍 Gate Verification Commands (Phase 5)
```bash
# 1. Run Lula assessment CLI
lula evaluate -f oscal-il5.yaml -o il5-results.json

# 2. Validate JSON evaluation output structure
python3 -c "import json; d=json.load(open('il5-results.json')); print('Lula Evaluation Passing:', d.get('results', [{}])[0].get('passing'))"
```
**Success Criteria:** `lula evaluate` executes successfully and returns `passing: true` across all defined IL4/IL5 controls.

---

## 🚩 Phase 6: Automated Accreditation Artifact Generation (SSP & SAR)

### Objective
Transform machine-readable OSCAL assessment JSON into human-readable System Security Plan (SSP) and Security Assessment Report (SAR) markdown documentation.

### Tasks
- [ ] Run `lula generate manifest` to generate compliance markdown.
- [ ] Write `scripts/generate_ato_package.py` to parse Lula JSON into executive PDF/Markdown summary.
- [ ] Export final accreditation artifact package into `docs/accreditation/`.

### 🔍 Gate Verification Commands (Phase 6)
```bash
# 1. Generate Markdown accreditation report
lula generate manifest -f il5-results.json -o docs/accreditation/IL5_SAR_Report.md

# 2. Verify presence of generated ATO artifact files
ls -la docs/accreditation/IL5_SAR_Report.md
```
**Success Criteria:** Complete, audit-ready IL4/IL5 Security Assessment Report (SAR) generated in `docs/accreditation/`.
