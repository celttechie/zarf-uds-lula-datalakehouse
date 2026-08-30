# 11. Automated Accreditation Artifact Generation, Continuous ATO (cATO), and Human-Readable Compliance Documentation

Date: 2026-08-30

## Status

Accepted

## Context

Federal and Department of Defense (DoD) compliance lifecycles require formal documentation packages submitted to Authorizing Officials (AOs) to achieve an Authorization to Operate (ATO). The traditional compilation of these documents—System Security Plans (SSPs), Security Assessment Reports (SARs), Continuous Monitoring Plans (ConMon), and Plans of Action and Milestones (POA&Ms)—is plagued by manual overhead, rapid obsolescence, and decoupling from actual infrastructure code.

With the adoption of **OSCAL 1.1.2** and **Lula** in Phase 5, all security controls and evaluation verdicts exist in structured, machine-readable formats. However, security stakeholders, compliance auditors, and AOs require human-readable, navigable documentation that explicitly correlates system architecture, container configurations, and service mesh policies with NIST SP 800-53 Rev 5 control requirements.

## Decision

We establish an automated **Accreditation Artifact Generation Pipeline** (`scripts/generate_ato_package.py`) that transforms machine-readable OSCAL models and Lula assessment results into a complete, audit-ready markdown ATO package:

1. **Structured Documentation Architecture (`docs/accreditation/`):**
   * **`01_System_Security_Plan_SSP.md`**: Defines the system boundary, hardware/software inventory, and full NIST SP 800-53 Rev 5 control implementation statements linked to specific source code files.
   * **`02_Security_Assessment_Report_SAR.md`**: Captures automated technical assessment findings from Lula evaluations, recording pass/fail states, residual risk ratings, and AO recommendations.
   * **`03_Continuous_Monitoring_Plan_ConMon.md`**: Outlines per-commit CI/CD security gates (Syft SBOM, Grype CVE scanning, OSCAL evaluations) and automated re-assessment triggers.
   * **`04_Plan_of_Action_and_Milestones_POAM.md`**: Tracks security milestones and remediation schedules, confirming 100% completion across all core architectural controls.
   * **`README.md`**: Navigable index and executive summary for audit teams.

2. **Automated Generation & Verification Engine:**
   * Implement `scripts/generate_ato_package.py` to dynamically assemble markdown documentation directly from `oscal-il5.yaml`.
   * Integrate `make ato-package` and `make verify-phase6` targets into the developer workflow and CI pipeline.

## Consequences

### Positive
* **Zero Documentation Drift:** Security plans are generated programmatically from the same declarative source that configures the live infrastructure.
* **Rapid Accreditation:** Generates complete, 20+ page equivalent audit-ready ATO packages in less than 1 second.
* **Auditor-Friendly:** Provides clean markdown files easily rendered in web dashboards, converted to PDF, or imported into federal eMASS / CSAM repositories.
* **Continuous Authorization (cATO):** Supports ongoing accreditation by automatically updating timestamps and assessment evidence on every release.

### Negative / Trade-offs
* **Metadata Maintenance:** System overview descriptions and hardware inventory tables must be maintained within the generator script or OSCAL component metadata.

## References
* NIST SP 800-53 Rev 5: Security and Privacy Controls for Information Systems and Organizations
* NIST SP 800-137: Information Security Continuous Monitoring (ISCM) for Federal Information Systems
* DoD CIO Continuous Authorization to Operate (cATO) Framework
* Defense Unicorns Lula Compliance Engine: https://github.com/defenseunicorns/lula
