# 3. Data Lakehouse Architecture and OSCAL Compliance Stack

Date: 2026-08-13

## Status

Accepted

## Context

The Senior FDE Data Engineer position requires experience with unstructured data at scale, data warehousing/lakehouses, and generating DoD IL4/IL5 accreditation artifacts.

## Decision

We adopt a 4-tier technology stack:

1. **Unstructured Data Lake (MinIO S3):** Stores raw multi-format payloads (JSON, text, XML) in an S3-compatible object store.
2. **Data Lakehouse Storage (Apache Parquet + PyArrow):** Converts raw unstructured data into columnar Parquet files stored in S3 for optimal compression and query speed.
3. **Data Warehousing Query Engine (DuckDB + PostgreSQL):** Executes analytical queries over Parquet data lake objects and populates gold-layer database tables.
4. **Continuous Accreditation Engine (Zarf + UDS + Lula):** Packages the stack into air-gapped `.tar.zst` bundles, enforces zero-trust service mesh rules (Istio mTLS), and continuously audits DoD IL4/IL5 controls using **OSCAL Component Definitions** and **Lula**.

## Consequences

* Provides a full end-to-end demonstration of data engineering at scale coupled with automated defense security compliance.
* Demonstrates hands-on mastery of Defense Unicorns' primary open-source ecosystem (Zarf, UDS, Lula).
