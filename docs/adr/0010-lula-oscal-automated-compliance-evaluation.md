# 10. Lula OSCAL Continuous Compliance Evaluation and DoD IL5 Security Controls as Code

Date: 2026-08-29

## Status

Accepted

## Context

Achieving and maintaining an Authority to Operate (ATO) in Department of Defense (DoD) Impact Level 4 (IL4) and Impact Level 5 (IL5) environments traditionally relies on static, point-in-time compliance spreadsheets, manual interviews, and disconnected word processing documents. This legacy workflow introduces significant risk:
1. **Compliance Drift:** Operational configurations, pod security contexts, and network policies drift over time without continuous automated verification.
2. **Disconnected Evidence:** Security documentation (System Security Plans) is detached from the live runtime state of the Kubernetes cluster.
3. **Audit Latency:** Compiling security assessment reports requires weeks of manual audits rather than instant, programmatic evaluation.
4. **Lack of Machine-Readable Standards:** Proprietary compliance templates cannot be integrated into automated DevSecOps CI/CD pipelines.

## Decision

We adopt **Lula** (Defense Unicorns Compliance Engine) and the **NIST Open Security Controls Assessment Language (OSCAL v1.1.2)** to implement Continuous Compliance as Code for the Medallion Data Lakehouse:

1. **Declarative OSCAL Component Definition (`oscal-il5.yaml`):**
   * Define machine-readable OSCAL 1.1.2 component definition for `data-lakehouse-medallion`.
   * Map architectural invariants directly to **NIST SP 800-53 Rev 5** security controls:
     * **`AC-3` (Access Enforcement):** Non-root execution (`runAsNonRoot: true`, `drop: [ALL]`, `allowPrivilegeEscalation: false`).
     * **`AC-4` (Information Flow Enforcement):** Istio `PeerAuthentication` in `STRICT` mTLS mode preventing cleartext ingress.
     * **`IA-2` (Identification & Authentication):** Cryptographic SPIFFE workload identity attribution.
     * **`SC-8` (Transmission Confidentiality & Integrity):** TLS 1.3 encryption across all intra-cluster pod traffic.
     * **`SC-13` (Cryptographic Protection):** Apache Parquet columnar block-level checksum verification (CRC32/Snappy).
     * **`SC-28` (Protection of Information at Rest):** Dedicated non-root volume mounts and immutable S3 object storage.
     * **`SI-4` (Information System Monitoring):** Structured telemetry logging and Kubernetes health probes.

2. **Automated Assessment Engine (`lula validate`):**
   * Execute programmatic validation of the OSCAL component definition against live cluster resources and policy manifests.
   * Generate standardized OSCAL `assessment-results.yaml` artifacts recording pass/fail states for all controls.

3. **High-Performance Golang Compliance Exporter (`bin/compliance_exporter`):**
   * Implement a native Go CLI (`src/compliance_exporter/main.go`) to ingest OSCAL assessment findings.
   * Render real-time terminal audit matrices, compute compliance scores, and export machine-readable metrics into CI/CD pipelines.

## Consequences

### Positive
* **Continuous ATO Readiness:** Compliance verification runs in milliseconds alongside unit and integration tests.
* **Audit Transparency:** Every control is explicitly linked to code, Helm values, and running Kubernetes specifications.
* **Zero Spreadsheet Drift:** Security controls are tracked directly in Git alongside the application and infrastructure code.
* **Automated Artifact Generation:** Produces standardized OSCAL data ready for downstream automated accreditation reporting.

### Negative / Trade-offs
* **Schema Rigor:** OSCAL v1.1.2 requires strict RFC 4122 UUIDv4 compliance and formal JSON Schema validation.
* **Toolchain Dependency:** Requires the `lula` CLI and Go runtime for compiling and executing compliance evaluations.

## References
* NIST SP 800-53 Rev 5 Security and Privacy Controls
* NIST OSCAL (Open Security Controls Assessment Language) v1.1.2
* Defense Unicorns Lula Compliance Engine: https://github.com/defenseunicorns/lula
