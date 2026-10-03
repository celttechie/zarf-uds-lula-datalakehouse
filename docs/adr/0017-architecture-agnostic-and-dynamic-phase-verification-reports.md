# 17. Architecture-Agnostic and Dynamic Phase Verification Reporting

Date: 2026-10-02

## Status

Accepted

## Context

Phase gate verification scripts (`scripts/verify_phase3.py`, `scripts/verify_phase4.py`, `scripts/verify_phase6.py`) automatically validate packaging, bundle orchestration, and accreditation readiness while writing formal Markdown verification artifacts into `docs/artifacts/`.

An audit of these scripts identified static assumptions and hardcoded values:
1. **Static Architecture Defaults**: `verify_phase3.py` and `verify_phase4.py` defaulted missing `metadata.architecture` fields in `zarf.yaml` and `uds-bundle.yaml` to `amd64`, failing to reflect the repository's multi-architecture design (`amd64` / `arm64`).
2. **Hardcoded Container Images**: Phase 3 checklists hardcoded legacy Quay registry image URLs (`quay.io/minio/minio:...`) rather than dynamically referencing the active multi-architecture image inventory from `values.yaml` (`cgr.dev/chainguard/minio:latest`).
3. **Hardcoded Host Hardware & Test Counts**: Phase 6 verification report templates hardcoded specific workstation models (`Xeon T5600`) and obsolete test counts (`26 tests`).

## Decision

We update the verification scripts to dynamically populate all verification reports and checklists:

### 1. Multi-Architecture Declarations
When `metadata.architecture` is omitted in `zarf.yaml` or `uds-bundle.yaml`, the scripts explicitly report `Multi-Architecture (amd64 / arm64)` to signify cross-architecture build capability.

### 2. Dynamic Image Checklist Generation
Phase 3 security checklists dynamically iterate through the actual image inventory defined in `zarf.yaml` / `values.yaml`, ensuring accurate cryptographic traceability.

### 3. Dynamic Unit Test & Hardware Summary
Phase 6 verification dynamically parses the test execution count from the test runner and refers to the multi-target authorization boundary (incorporating live cluster nodes or multi-target matrix) established in ADR 0014.

## Consequences

### Positive
* **Complete Architectural Parity**: All phase reports in `docs/artifacts/` accurately represent multi-architecture support across `arm64` and `amd64`.
* **Zero Stale Image Tags**: Checklists automatically synchronize with updated container base images.
* **Accurate Gate Metrics**: Verification summaries reflect exact, real-time unit test counts.

### Negative / Trade-offs
* None identified.

## References
* Zarf Package Specification: https://docs.zarf.dev/
* UDS Bundle Specification: https://uds.defenseunicorns.com/
