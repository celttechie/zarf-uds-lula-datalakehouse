# Continuous Monitoring Plan (ConMon): DoD IL5 Medallion Data Lakehouse

**Effective Date:** 2026-08-31 21:16:50Z  
**Review Frequency:** Continuous (Per-Commit Automated CI/CD & Weekly Scheduled Cluster Scans)  
**Governance Framework:** NIST SP 800-137 / DoD Continuous Authorization to Operate (cATO)  

---

## 1. Continuous Monitoring Architecture

The Data Lakehouse implements continuous security validation through declarative Compliance-as-Code:

```text
┌────────────────────────────────────────────────────────────────────────┐
│               CONTINUOUS ATO (cATO) MONITORING PIPELINE                │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Git Commit / PR ──► GitHub Actions CI ──► OpenTofu / Helm Lint      │
│ 2. Automated Build ──► Syft SBOM Gen ─────► Grype Vulnerability Scan   │
│ 3. Policy Audit    ──► Lula Validate ──────► OSCAL Compliance Matrix   │
│ 4. Deployment Gate ──► Zarf Package Verify ─► Deploy to K8s Cluster    │
│ 5. Runtime Audit   ──► Istio mTLS Telemetry► Continuous SI-4 Logging   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Automated Monitoring Cadence & Trigger Matrix

| Monitoring Activity | Tool / Mechanism | Frequency / Trigger | Alert / Action Threshold |
| :--- | :--- | :--- | :--- |
| **OSCAL Policy Validation** | `lula validate -f oscal-il5.yaml` | Every PR & Git Push | Any unsatisfied control blocks merge |
| **Container Vulnerability Scan** | Syft & Grype Scanner | Every Image Build | Critical / High CVEs block deployment |
| **Air-Gap Package Signature** | `zarf package create --key` | Release Tag | Cosign cryptographic signature required |
| **Cluster Pod Security Audit** | Kubernetes Admission Controller | Real-Time (Runtime) | Prevents privileged container execution |
| **TLS Certificate Rotation** | Istio Citadel CA | Every 24 Hours | Automated SPIFFE SVID rotation |

---

## 3. Incident Response & Re-Assessment Triggers

A formal security re-evaluation is automatically triggered upon:
1. Significant architectural change or new data source onboarding.
2. Introduction of newly discovered Zero-Day CVEs in upstream base images.
3. Modification of cluster network policies or Istio mTLS configurations.
