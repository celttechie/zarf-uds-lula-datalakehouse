# 15. Dynamic OSCAL Assessment Ingestion in Security Assessment Report (SAR) Generation

Date: 2026-10-02

## Status

Accepted

## Context

The Security Assessment Report (SAR) in `docs/accreditation/02_Security_Assessment_Report_SAR.md` is a critical component of the DoD IL5 Continuous Authorization to Operate (cATO) artifact package. It provides Authorizing Officials (AOs) with formal assessment results, per-control satisfaction statuses, assessor engine metadata, and residual risk determinations.

In the initial implementation, `scripts/generate_ato_package.py` used a semi-static template with hardcoded engine version strings (e.g. `Lula Engine v0.9.5`) and a pre-rendered table of 7 control verdicts. While these matched the expected outcomes, they did not dynamically reflect live execution results from the actual Lula / OSCAL assessment run (`assessment-results.yaml` or `il5-results.yaml`).

## Decision

We update `scripts/generate_ato_package.py` to dynamically parse and ingest live OSCAL assessment results when generating the SAR:

### 1. Dynamic OSCAL Findings Ingestion
`generate_sar()` inspects the local filesystem for active OSCAL assessment artifacts (`assessment-results.yaml` or `il5-results.yaml`):
* **Live Assessor Metadata**: Extracts the exact evaluator tool name, version, and assessment timestamp from the assessment file or active `lula version` CLI.
* **Dynamic Control Findings**: Iterates through each evaluated control requirement (`oscal-il5.yaml`), matching live validation observations (satisfied vs unsatisfied).
* **Automated Compliance Scoring**: Computes the real-time compliance percentage (e.g. `100.0% (7/7 Controls Satisfied)`) and formats individual finding rows with clear visual indicators (🟢 **PASS** / 🔴 **FAIL**).

### 2. Graceful Pre-Flight Fallback
If the ATO package is generated before `make audit` has been run or without an existing assessment results artifact, the generator evaluates the declarative baseline rules directly and marks the assessment mode as `DECLARATIVE_BASELINE_EVALUATION` with clear traceability.

### 3. Automated Unit Testing
Updated unit tests in `tests/test_ato_package.py` to verify that dynamic finding tables and assessor strings are correctly populated and synchronized with OSCAL model definitions.

## Consequences

### Positive
* **Auditable Integrity**: The SAR reflects actual, real-time cryptographic and security evaluations from the active cluster instead of static boilerplate text.
* **Fail-Visible Reporting**: Any failing or unsatisfied control in the cluster immediately appears as a failure in the SAR.
* **Multi-Environment Adaptability**: Accurate assessment reporting across Orange Pi edge devices, local KVM sandboxes, and AWS EKS clusters.

### Negative / Trade-offs
* Requires syncing with `assessment-results.yaml` schema conventions (OSCAL 1.1.2 assessment-results model).

## References
* NIST SP 800-53A Rev 5: Assessing Security and Privacy Controls in Information Systems
* OSCAL v1.1.2 Assessment Results Model Specification
