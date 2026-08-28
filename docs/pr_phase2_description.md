## 📌 Summary of Changes

This PR completes **Phase 2 (Data Lakehouse Core & ETL Pipeline)** of the master execution plan:
- **Medallion ETL Core:** Implemented `src/lakehouse_etl.py` executing multi-tier Medallion architecture (Bronze MinIO raw JSON -> Silver DuckDB/PyArrow columnar Parquet -> Gold PostgreSQL relational analytics) with automated service readiness retry logic.
- **Kubernetes Helm Chart:** Built and validated Helm templates under `k8s/charts/datalakehouse/` for MinIO, PostgreSQL, ConfigMap, and the Medallion ETL Job with DoD IL4/IL5 compliant security contexts.
- **Automated Test Suite:** Created unit tests in `tests/` validating ETL execution flow, schema upsert logic, and Helm template structural integrity.
- **Nested Sandbox Infra Hardening:** Updated Stage 2 K8s node Terraform module (`terraform/modules/k8s_cluster_nodes/main.tf`) to enable `host-passthrough` CPU virtualization mode.

---

## 🏷️ Type of Change
- [x] 🚀 `feat`: New feature or capability
- [x] 🐛 `fix`: Bug fix (CPU host-passthrough & MinIO volume permissions)
- [x] 🧪 `test`: Unit / integration test additions
- [x] 🔧 `chore`: Build scripts, dependencies, CI/CD

---

## 📑 Architecture Decision Records (ADRs) Addressed
- **Satisfies [ADR-0003: Data Lakehouse Architecture and OSCAL Compliance Stack](docs/adr/0003-data-lakehouse-and-oscal-compliance-stack.md):** Implements Bronze (S3 raw JSON) -> Silver (Parquet) -> Gold (PostgreSQL) data flow powered by DuckDB.
- **Satisfies [ADR-0005: Helm Packaging, Go Compliance Exporter, and UDS Connect](docs/adr/0005-helm-packaging-and-golang-exporter.md):** Packages Lakehouse components into standard Helm chart templates consumed natively by Zarf and UDS.
- **Hardens [ADR-0006: Two-Stage Nested Sandbox Architecture](docs/adr/0006-nested-sandbox-hypervisor-and-ssh-host-keys.md):** Configures CPU `host-passthrough` mode in Stage 2 cluster nodes to expose host AVX/SSE4.2 CPU features to nested container workloads.
- **Validates [ADR-0007: Decoupled Infrastructure-Agnostic Delivery](docs/adr/0007-decoupled-infrastructure-agnostic-delivery.md):** Demonstrates pure Kubernetes API decoupling across local and sandbox environments.

---

## 🧪 Verification & Testing Gates

### 1. Automated Unit & Syntax Tests
```bash
python3 -m unittest discover tests
```
**Result:** `4/4 passed (0 failures)`
- `test_lakehouse_etl.py`: Verified Bronze upload, Silver Parquet transformation, and Gold upsert logic.
- `test_helm_templates.py`: Verified `Chart.yaml`, `values.yaml`, and template bracket balancing.

### 2. Helm Linting & Template Rendering
```bash
helm lint k8s/charts/datalakehouse
```
**Result:** `1 chart(s) linted, 0 chart(s) failed`

### 3. Live K3s Sandbox Cluster Deployment (Dell Precision T5600)
```bash
# Deployed release datalakehouse onto Stage 2 K3s workload node (192.168.122.60)
sudo k3s kubectl get pods,svc,jobs -o wide
```
**Output:**
```text
NAME                                       READY   STATUS      RESTARTS   AGE   IP
pod/datalakehouse-minio-69f569d89d-w8wh8   1/1     Running     0          36s   10.42.0.20
pod/postgresql-bb49dbf4c-w7wv8             1/1     Running     1          22m   10.42.0.16
pod/medallion-etl-job-78vcw                0/1     Completed   0          36s   10.42.0.21

NAME                          STATUS     COMPLETIONS   DURATION
job.batch/medallion-etl-job   Complete   1/1           30s
```

**PostgreSQL Gold Table Query Output:**
```sql
SELECT * FROM category_sales_metrics;

  category   | total_transactions | total_sales |        last_updated        
-------------+--------------------+-------------+----------------------------
 Electronics |                  2 |      200.50 | 2026-08-18 16:16:51.105038
 Groceries   |                  2 |      375.25 | 2026-08-18 16:16:51.105038
 Clothing    |                  2 |      300.00 | 2026-08-18 16:16:51.105038
(3 rows)
```

---

## 🛡️ Security & DoD IL4/IL5 Compliance Checklist
- [x] **Non-Root Containers:** MinIO and PostgreSQL configured with non-root UID/GID (`runAsNonRoot: true`, `fsGroup: 1000/999`).
- [x] **Privilege Escalation:** Disabled (`allowPrivilegeEscalation: false`) and capabilities dropped (`drop: [ALL]`).
- [x] **Deterministic Infrastructure:** Verified deterministic ED25519 SSH host keys for Stage 1 and Stage 2.
