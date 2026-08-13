# 5. Helm Packaging, Go Compliance Exporter, and UDS Connect

Date: 2026-08-13

## Status

Accepted

## Context

To provide a complete portfolio demonstration matching all Defense Unicorns core requirements (Zarf, UDS, Lula, K8s/Helm, Go/Golang, Terraform, and UDS Connect UI), the project requires standard Helm packaging, custom Go CLI utilities, and UI console access.

## Decision

1. **Helm Chart Integration (`k8s/charts/datalakehouse`):** Package the Data Lakehouse components into a standard Helm Chart consumed natively by Zarf in `zarf.yaml`.
2. **Go (Golang) Exporter (`src/compliance_exporter/main.go`):** Implement a Go CLI tool to parse Lula OSCAL evaluation JSON results into formatted terminal reports and metrics.
3. **UDS Connect & Ingress Dashboard Access:** Expose UDS Connect, Keycloak SSO, and MinIO S3 consoles via Istio Ingress hostnames (`connect.datalake.local`, `minio.datalake.local`, `auth.datalake.local`).
4. **Makefile & CI/CD:** Provide 1-command targets (`make dev-vm`, `make deploy`, `make audit`) and GitHub Actions integration (`.github/workflows/ci.yml`).

## Consequences

* Enables zero-friction local execution for recruiters and engineers cloning the repo.
* Demonstrates full multi-language proficiency across Python, Go, and HCL/YAML.
