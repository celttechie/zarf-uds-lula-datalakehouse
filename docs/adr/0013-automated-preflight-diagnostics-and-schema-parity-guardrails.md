# 13. Automated Pre-Flight Environment Diagnostics and Declarative Schema Parity Guardrails

Date: 2026-09-15

## Status

Accepted

## Context

Deploying the **DoD IL4/IL5 Medallion Data Lakehouse** across ephemeral multi-cloud targets (AWS EC2 K3s and Managed EKS) requires strict coordination across several declarative layers:
1. **Cloud Account & IAM Authentication**: AWS IAM access keys, STS identity attribution, and account activation verification.
2. **Workstation Toolchain**: OpenTofu/Terraform, Zarf, UDS CLI, and Kubectl binaries.
3. **Declarative Packaging Schemas**: Zarf package definitions (`zarf.yaml`), UDS bundles (`uds-bundle.yaml`), runtime configuration overlays (`uds-config*.yaml`), and Helm values (`values.yaml`).
4. **Continuous Compliance Evaluation**: OSCAL assessment schemas (`oscal-il5.yaml`), assessment results parsing, and ATO reporting.

During initial cloud deployments, subtle environmental issues (such as new AWS account verification holds, missing CLI binaries, legacy UDS config schema wrappers, and Docker Hub container rate-limiting) caused failures during active deployment stages. To ensure robust, repeatable, and fail-fast operations, the repository requires automated pre-flight diagnostics and comprehensive schema parity unit tests.

## Decision

We implement a multi-layered validation and diagnostic framework integrated directly into developer workflows:

### 1. Pre-Flight Diagnostic Doctor (`scripts/doctor.py` & `make doctor`)
* **AWS Authentication & Account Diagnostics**: Validates STS caller identity, permissions, and confirms the account is not under an automated activation hold.
* **CLI Toolchain Scanner**: Checks for required (`python3`, `tofu`/`terraform`) and optional (`zarf`, `uds`, `kubectl`, `go`, `lula`) binaries, providing copy-paste install hints when missing.
* **Air-Gap Asset Cache Verifier**: Confirms `~/.zarf-cache` readiness to prevent interactive prompts or local root permission failures during `zarf init`.
* **Schema & Immutability Pre-Check**: Validates cross-file package naming, UDS variable mapping, author formatting, and container tag immutability before cloud provisioning begins.

### 2. Cross-File Declarative Schema Parity Tests
* **Package Name Alignment**: Strict unit tests assert `zarf.yaml: metadata.name` matches `uds-bundle.yaml: packages[].name` and `uds-config*.yaml: variables.<name>`.
* **Local Package Isolation**: Enforces mutual exclusivity between `path` and `repository` on local Zarf packages in UDS bundles.
* **Three-Tier Override Hierarchy**: Validates that all bundle overrides strictly adhere to `<component> -> <chart> -> values` structure.
* **Storage Class Overlay Invariants**: Ensures `local-path` is strictly enforced for EC2 K3s and `gp3` is strictly enforced for Managed EKS.

### 3. Zero-Dependency Python Tooling Fallbacks
* To eliminate hard dependencies on the Go compiler or external binary release downloads on developer workstations:
  * **`scripts/validate_compliance.py`**: Native Python engine for validating `oscal-il5.yaml` against live Kubernetes clusters and generating `assessment-results.yaml`.
  * **`scripts/compliance_exporter.py`**: Native Python parser for computing compliance scores and rendering NIST SP 800-53 Rev 5 matrices.
  * The Makefile automatically compiles and utilizes the Go exporter if `go` is installed, and seamlessly falls back to Python if it is absent.

### 4. Verified Container Registry Pinning
* Pinned MinIO S3 container images to official immutable releases on Quay (`quay.io/minio/minio:RELEASE.2024-01-16T16-07-38Z`) to prevent Docker Hub anonymous pull limits and authentication failures.

### 5. EKS 1.30+ AL2023 Node Groups & Default `gp3` StorageClass Automation
* Configured Managed Node Groups to use standard Amazon Linux 2023 (`ami_type = "AL2023_x86_64_STANDARD"`), preventing `InvalidParameterException: Requested AMI for this version 1.30 is not supported` caused by deprecated AL2 AMIs.
* Automated the registration of the default `gp3` StorageClass (`storageclass.kubernetes.io/is-default-class: "true"`) in `scripts/fetch_aws_kubeconfig.sh` upon EKS cluster creation, ensuring dynamic EBS volume binding for Zarf registry and Lakehouse PVCs without manual intervention.

## Consequences

### Positive
* **Fail-Fast Confidence**: Developers identify and resolve AWS credentials, missing tools, or schema errors in seconds before spinning up cloud resources.
* **Zero External Compiler Friction**: The platform operates seamlessly with standard Python 3, while preserving full support for Golang toolchains.
* **Deterministic Dual-Tier Cloud Deployment**: Complete parity across local KVM nested sandboxes, AWS EC2 K3s, and AWS Managed EKS.

### Negative / Trade-offs
* **Maintenance Overhead**: Requires maintaining unit test assertions when adding new Helm charts or UDS bundle components.

## References
* Defense Unicorns UDS CLI Documentation: https://uds.defenseunicorns.com/
* Defense Unicorns Zarf Packaging: https://docs.zarf.dev/
* NIST SP 800-53 Rev 5: https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final

