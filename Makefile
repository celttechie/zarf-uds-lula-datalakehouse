.PHONY: help dev-vm dev-destroy package deploy audit go-build clean

help: ## Display available Makefile target commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

dev-vm: ## Provision development hypervisor VM via Terraform libvirt
	@echo "🚀 Provisioning Dev VM infrastructure..."
	cd terraform/environments/dev && terraform init && terraform apply -auto-approve

dev-destroy: ## Destroy development hypervisor VM via Terraform libvirt
	@echo "💥 Destroying Dev VM infrastructure..."
	cd terraform/environments/dev && terraform destroy -auto-approve

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
	rm -rf bin/ zarf-package-*.tar.zst il5-results.json
