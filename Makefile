.PHONY: help dev-sandbox dev-cluster dev-destroy-all verify-phase1 package deploy audit go-build clean

help: ## Display available Makefile target commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

dev-sandbox: ## Provision Stage 1 Nested Sandbox VM via Terraform
	@echo "🚀 Provisioning Stage 1 Nested Sandbox hypervisor..."
	cd terraform/environments/01-nested-sandbox && terraform init && terraform apply -auto-approve

dev-cluster: ## Provision Stage 2 K8s Cluster Node via Terraform
	@echo "🚀 Provisioning Stage 2 K8s cluster node inside sandbox..."
	cd terraform/environments/02-k8s-cluster && terraform init && terraform apply -auto-approve

dev-destroy-all: ## Destroy all Stage 1 & Stage 2 Terraform infrastructure
	@echo "💥 Destroying Stage 2 K8s cluster node..."
	-cd terraform/environments/02-k8s-cluster && terraform destroy -auto-approve
	@echo "💥 Destroying Stage 1 Sandbox hypervisor..."
	-cd terraform/environments/01-nested-sandbox && terraform destroy -auto-approve

verify-phase1: ## Run automated Phase 1 verification and generate Markdown artifact report
	@echo "🔍 Running automated Phase 1 health check & generating artifact report..."
	python3 scripts/verify_phase1.py

package: ## Build Zarf air-gapped package (.tar.zst)
	@echo "📦 Building Zarf package..."
	zarf package create --confirm

deploy: ## Deploy UDS Bundle into target K8s cluster
	@echo "🚀 Deploying UDS Bundle & Core infrastructure..."
	uds deploy --confirm

audit: go-build ## Run Lula OSCAL continuous compliance evaluation and Go exporter
	@echo "🛡️  Executing Lula OSCAL evaluation..."
	lula evaluate -f oscal-il5.yaml -o il5-results.json
	@echo "📊 Parsing OSCAL findings using Go Exporter..."
	./bin/compliance_exporter il5-results.json

go-build: ## Build Golang OSCAL compliance exporter binary
	@echo "🐹 Building Go compliance exporter CLI..."
	mkdir -p bin
	go build -o bin/compliance_exporter src/compliance_exporter/main.go

clean: ## Clean up local build artifacts and cache
	@echo "🧹 Cleaning up artifacts..."
	rm -rf bin/ zarf-package-*.tar.zst il5-results.json docs/artifacts/
