# 9. UDS Bundle Orchestration, Istio STRICT mTLS Service Mesh, and Zero-Trust Cluster Deployment

Date: 2026-08-28

## Status

Accepted

## Context

Deploying mission-critical data lakehouse workloads into Department of Defense (DoD) Impact Level 4 (IL4) and Impact Level 5 (IL5) environments requires unified multi-package orchestration, cryptographic zero-trust networking, and centralized identity integration.

While standalone Zarf packages encapsulate individual application artifacts (Helm charts, manifests, and OCI images), enterprise-scale deployments require coordinating application workloads with foundational platform capabilities:
1. **Multi-Package Lifecycle Management:** Managing dependencies between application workloads (`il5-data-lakehouse`) and core platform infrastructure (`uds-core`: Istio, Keycloak, Pepr) without brittle shell scripts or manual coordination.
2. **Cryptographic Data-in-Transit Protection (NIST SC-8):** DoD IL4/IL5 mandates that all service-to-service communication across the Kubernetes cluster be encrypted using mutual TLS (mTLS) with cryptographically validated cryptographic identities.
3. **Zero-Trust Network Access Control (NIST AC-3, AC-4):** Default open ingress within the cluster network violates least-privilege security principles; data lakehouse endpoints (MinIO S3 on ports 9000/9001 and PostgreSQL on port 5432) must be strictly restricted to authenticated and authorized SPIFFE service account identities.
4. **Declarative Runtime Configuration:** Target cluster differences (e.g. storage classes, domains, security baseline overrides) must be parameterized declaratively rather than requiring manual manifest edits.

## Decision

We adopt **Defense Unicorns UDS (Unicorn Delivery System)** and **Istio Service Mesh** to orchestrate cluster deployment and enforce zero-trust security controls:

1. **Declarative UDS Bundle Specification (`uds-bundle.yaml`):**
   * Define `kind: UDSBundle` (metadata: `il5-data-lakehouse-bundle`, version `0.4.0`, architecture `amd64`).
   * Reference the primary workload package `datalakehouse` (`zarf-package-il5-data-lakehouse`) with component variable and value overrides (`STORAGE_CLASS: local-path`, `SECURITY_PROFILE: il5-strict`, `mesh.mtls.mode: STRICT`).
   * Define integration points for `uds-core` (Istio service mesh, Pepr IL5 admission control, Keycloak realm configuration).

2. **Namespace-Wide Istio STRICT mTLS (`k8s/mesh/peer-authentication.yaml`):**
   * Deploy an Istio `PeerAuthentication` resource configured with `mtls.mode: STRICT` in the `datalakehouse` namespace.
   * Reject all plain-text TCP/HTTP traffic; require mutual TLS encryption and certificate validation across all pod-to-pod and gateway-to-pod communication.

3. **Least-Privilege Zero-Trust Authorization Policy (`k8s/mesh/authorization-policy.yaml`):**
   * Apply an Istio `AuthorizationPolicy` (`action: ALLOW`) restricting ingress access to MinIO S3 API & Console (ports 9000, 9001) and PostgreSQL (port 5432).
   * Restrict access strictly to validated SPIFFE identities: intra-namespace service accounts (`cluster.local/ns/datalakehouse/sa/*`), Istio/UDS Core Ingress Gateway (`cluster.local/ns/istio-system/sa/*`, `cluster.local/ns/uds-core/sa/*`), and administrative audit services (Pepr, Keycloak, Prometheus).

4. **Parameterized Bundle Configuration (`uds-config.yaml`):**
   * Standardize bundle creation and deployment settings including target namespace, ingress domain (`datalake.local`), storage persistence, and security level baseline (`IL5`).

5. **Automated Unit Testing & Gate Verification (`tests/test_uds_bundle.py`, `scripts/verify_phase4.py`):**
   * Implement automated test suites validating UDS bundle schema, package overrides, Istio mTLS and authorization policy manifests, and bundle-Zarf compatibility.
   * Generate an audit-ready Phase 4 verification report at `docs/artifacts/phase4_verification_report.md`.

## Consequences

* **Unified Multi-Package Orchestration:** The UDS bundle provides a single artifact and command (`uds deploy`) to deploy the entire data lakehouse and service mesh stack deterministically.
* **Cryptographic Zero-Trust Enforcement:** STRICT mTLS and least-privilege AuthorizationPolicies satisfy DoD IL4/IL5 controls (NIST SP 800-53 SC-8, SC-13, AC-3, AC-4, IA-2) out-of-the-box.
* **Declarative Parameterization:** Runtime configuration enables seamless portability across different Kubernetes platforms (K3s, RKE2, EKS, bare-metal).
* **Resource Overhead:** Istio sidecar proxies add slight CPU and memory overhead per pod (~50MB RAM, <0.1 CPU core), which is standard for defense-grade service mesh deployments.
