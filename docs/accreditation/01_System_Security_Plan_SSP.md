# System Security Plan (SSP): DoD IL5 Medallion Data Lakehouse

**Document Identifier:** SSP-IL5-LAKEHOUSE-001  
**System Name:** data-lakehouse-medallion  
**System Version:** 1.0.0  
**Security Categorization:** DoD Impact Level 5 (IL5) / NIST SP 800-53 Rev 5 High-Watermark  
**Authorization Boundary:** Air-Gapped Kubernetes Cluster (Dell Precision T5600 Homelab & Production Target)  
**Publication Date:** 2026-08-31 12:05:41Z  

---

## 1. System Overview & Architecture Boundary

The **data-lakehouse-medallion** is an air-gapped, zero-trust analytical data platform engineered for high-assurance DoD environments. It ingests raw telemetry into an immutable S3 Bronze layer (MinIO), executes vectorized column-pruned transformations into Snappy-compressed Apache Parquet Silver storage (DuckDB), and materializes business-level aggregated metrics into an ACID-compliant PostgreSQL Gold database.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DoD IL5 AUTHORIZATION BOUNDARY                           │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  ☸️ Kubernetes Cluster (datalakehouse namespace)                       │  │
│  │                                                                       │  │
│  │  ┌────────────────────────┐         ┌──────────────────────────────┐  │  │
│  │  │  📦 MinIO S3 Storage   │ ◄─────► │  ⚡ DuckDB Vectorized Engine  │  │  │
│  │  │  • s3://bronze (JSON)  │  mTLS   │  • Snappy Apache Parquet     │  │  │
│  │  │  • s3://silver (Parquet│         │  • Zero-Copy Arrow Queries   │  │  │
│  │  └───────────┬────────────┘         └──────────────┬───────────────┘  │  │
│  │              │                                     │                  │  │
│  │              └──────────────────┬──────────────────┘                  │  │
│  │                                 │ mTLS STRICT (TLS 1.3)               │  │
│  │                                 ▼                                     │  │
│  │                     ┌───────────────────────┐                         │  │
│  │                     │ 📊 PostgreSQL 15 Gold │                         │  │
│  │                     │ • category_sales      │                         │  │
│  │                     │ • Acid Serving Mart   │                         │  │
│  │                     └───────────────────────┘                         │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│  🔒 Istio Service Mesh (STRICT mTLS, SPIFFE x509, Envoy Sidecar Proxies)     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Hardware & Software Inventory

| Component Name | Category | Version / Spec | Purpose & Security Role |
| :--- | :--- | :--- | :--- |
| **Dell Precision T5600** | Bare-Metal Host | 2x Intel Xeon, 64GB ECC RAM | Hypervisor host executing isolated hardware virtualization |
| **K3s / RKE2** | Container Engine | v1.28.8+k3s1 (containerd) | CIS-hardened Kubernetes orchestration layer |
| **MinIO** | Object Storage | RELEASE.2024-01-16T16-07-38Z | S3-compatible immutable raw object storage |
| **DuckDB / PyArrow** | Analytical Engine | 1.5.5 / 25.0.1 | Embedded in-process vectorized SQL execution (no TCP daemon) |
| **PostgreSQL** | Relational DB | 15-alpine | ACID-compliant Gold analytical serving warehouse |
| **Istio Service Mesh** | Cryptographic Proxy | 1.20+ (UDS Core) | Enforces STRICT mTLS and SPIFFE workload identity |
| **Zarf / UDS** | Package Delivery | 0.32.5 / 0.13.0 | Cryptographic air-gapped package validation and Syft SBOM |

---

## 3. NIST SP 800-53 Rev 5 Control Implementation Matrix

### Control AC-3: Access Enforcement & Least Privilege
* **NIST Reference:** `NIST SP 800-53 Rev 5 § AC-3`
* **Security Domain:** Access Control
* **Implementation Details:** Kubernetes Pod Security Standards: Containers enforce `runAsNonRoot: true`, `readOnlyRootFilesystem: false`, `allowPrivilegeEscalation: false`, and `capabilities.drop: [ALL]`.
* **Technical Evidence & Source Artifacts:** `k8s/charts/datalakehouse/templates/postgres-deployment.yaml, deployment.yaml, etl-job.yaml`

---
### Control AC-4: Information Flow Enforcement
* **NIST Reference:** `NIST SP 800-53 Rev 5 § AC-4`
* **Security Domain:** Access Control
* **Implementation Details:** Istio Service Mesh PeerAuthentication in STRICT mTLS mode across the datalakehouse namespace.
* **Technical Evidence & Source Artifacts:** `k8s/charts/datalakehouse/templates/peer-authentication.yaml, uds-bundle.yaml`

---
### Control IA-2: Identification and Authentication (Workload Identities)
* **NIST Reference:** `NIST SP 800-53 Rev 5 § IA-2`
* **Security Domain:** Identification & Authentication
* **Implementation Details:** Cryptographic SPIFFE X.509 SVID identities attributed and rotated dynamically by Istio Citadel CA.
* **Technical Evidence & Source Artifacts:** `Istio Envoy Sidecar SPIFFE trust domain configuration & UDS Core bundle`

---
### Control SC-8: Transmission Confidentiality and Integrity
* **NIST Reference:** `NIST SP 800-53 Rev 5 § SC-8`
* **Security Domain:** System & Communications Protection
* **Implementation Details:** Wire-level TLS 1.3 encryption across all inter-service S3 REST APIs, PostgreSQL wire protocol, and cluster RPC.
* **Technical Evidence & Source Artifacts:** `Istio Envoy proxy transparent encryption & TLS certificate rotation`

---
### Control SC-13: Cryptographic Protection (Columnar Data Checksums)
* **NIST Reference:** `NIST SP 800-53 Rev 5 § SC-13`
* **Security Domain:** System & Communications Protection
* **Implementation Details:** Apache Parquet Snappy compression with block-level CRC32 checksums verifying analytical column integrity.
* **Technical Evidence & Source Artifacts:** `src/lakehouse_etl.py (DuckDB Parquet Snappy export)`

---
### Control SC-28: Protection of Information at Rest
* **NIST Reference:** `NIST SP 800-53 Rev 5 § SC-28`
* **Security Domain:** System & Communications Protection
* **Implementation Details:** Dedicated non-root filesystem volume mounts for MinIO object store and PostgreSQL database files, with immutable raw S3 storage.
* **Technical Evidence & Source Artifacts:** `k8s/charts/datalakehouse/templates/postgres-deployment.yaml (PGDATA=/var/lib/postgresql/data/pgdata)`

---
### Control SI-4: Information System Monitoring
* **NIST Reference:** `NIST SP 800-53 Rev 5 § SI-4`
* **Security Domain:** System & Information Integrity
* **Implementation Details:** Kubernetes liveness/readiness probes, container restart policies, and structured JSON telemetry logs exported to Prometheus/OpenTelemetry.
* **Technical Evidence & Source Artifacts:** `k8s/charts/datalakehouse/templates/service.yaml, deployment.yaml, etl-job.yaml`

---
