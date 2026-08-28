# 8. Zarf Air-Gapped Immutable Packaging, OCI Image Bundling, and SBOM Generation

Date: 2026-08-28

## Status

Accepted

## Context

Deploying data lakehouse and analytics workloads into Department of Defense (DoD) Impact Level 4 (IL4) and Impact Level 5 (IL5) environments requires operating within zero-trust, physically or logically air-gapped networks.

Standard Kubernetes deployments rely on live egress to external container registries (e.g., Docker Hub, Quay, GitHub Container Registry) and public Helm repositories. In disconnected national security enclaves, this design introduces critical points of failure:
1. **Network Egress Failure:** Runtime image pull requests (`ErrImagePull`, `ImagePullBackOff`) fail immediately in air-gapped enclaves without external connectivity.
2. **Supply Chain Non-Compliance:** Unpinned or dynamic image tags (`:latest`) violate zero-trust provenance and configuration baseline requirements.
3. **Accreditation & SBOM Gaps:** DoD compliance mandates comprehensive, cryptographic Software Bill of Materials (SBOM) for all container layers and OS packages prior to Authorization to Operate (ATO).

## Decision

We adopt **Defense Unicorns Zarf** (`zarf.yaml`) as the standard immutable air-gapped delivery and packaging engine for the Medallion Data Lakehouse:

1. **Declarative Immutable Packaging (`zarf.yaml`):**
   * Package metadata defines `il5-data-lakehouse` (v0.3.0) targeting `amd64`.
   * Component `datalakehouse-core` encapsulates the local Helm chart (`k8s/charts/datalakehouse`) and deploys it natively into the `datalakehouse` namespace.
2. **Explicit OCI Image Bundling & Immutable Tag Pinning:**
   * Bundle all container images required by the Medallion Data Lakehouse into the compressed `.tar.zst` archive:
     - `minio/minio:RELEASE.2024-01-16T16-07-38Z` (Bronze/Silver object store)
     - `postgres:15-alpine` (Gold relational data warehouse)
     - `python:3.11-slim` (Medallion PyArrow/DuckDB ETL runner)
   * Enforce strict semantic or release tags, explicitly prohibiting mutable tags (`:latest`).
   * On cluster deployment (`zarf package deploy`), Zarf automatically seeds the internal cluster registry and mutates Helm image references to pull locally without egress.
3. **Post-Deployment Zero-Trust Verification Actions:**
   * Configure declarative `onDeploy` action hooks in `zarf.yaml` to verify pod health and service readiness before reporting deployment completion.
4. **Decoupled Runtime Configuration (`zarf-config.yaml`):**
   * Provide declarative configuration variables for cluster namespace, ingress domain, and storage retention settings.
5. **Continuous Verification Gates:**
   * Implement automated unit testing (`tests/test_zarf_package.py`) and verification scripting (`scripts/verify_phase3.py`) to validate packaging integrity, Helm chart syntax, and image parity before distribution.

## Consequences

* **Self-Contained Portability:** The resulting `.tar.zst` artifact requires zero internet or registry access during deployment.
* **Automated Supply Chain Security:** Generates Syft/Grype SBOMs and SHA-256 layer checksums automatically during package creation.
* **Seamless UDS Integration:** The Zarf package serves as the foundational deployment component for UDS Bundle orchestration in Phase 4.
* **Package Footprint:** Bundling image layers into a single archive increases package file size (~500MB - 1GB), requiring appropriate distribution bandwidth for air-gapped media transfer.
