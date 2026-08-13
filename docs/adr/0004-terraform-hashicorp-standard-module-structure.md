# 4. Adopt HashiCorp Standard Module Structure for Terraform

Date: 2026-08-13

## Status

Accepted

## Context

HashiCorp guidelines specify a clear separation between reusable infrastructure building blocks (**modules**) and environment deployments (**root modules/environments**).

## Decision

We restructure the Terraform directory to strictly follow HashiCorp's Standard Module Structure:

```
terraform/
├── modules/
│   └── libvirt_vm/               # Reusable child module (main.tf, variables.tf, outputs.tf)
│       └── templates/
│           └── cloud_init.cfg
└── environments/
    └── dev/                      # Root deployment module sourcing ../../modules/libvirt_vm
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars.example
```

## Rationale

* **Modularity:** Encapsulates VM creation logic into a single, reusable child module (`modules/libvirt_vm`).
* **Dry Configuration:** Environment directories (`environments/dev`, `environments/prod`) remain lightweight by referencing the shared module source.
* **HashiCorp Compliance:** Follows official Terraform registry layout guidelines and standard industry conventions.
