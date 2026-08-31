.PHONY: help ci dev-sandbox dev-cluster dev-destroy-all verify-phase1 test inspect verify-phase3 verify-phase4 verify-phase5 verify-phase6 ato-package package deploy audit go-build clean

help: ## Display available Makefile target commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

ci: test go-build ## Run full local CI/CD pre-flight simulation (OpenTofu, Helm, Tests, Go)
	@echo "==> 1. Validating OpenTofu Environments..."
	@for env in terraform/environments/*; do \
		if [ -d "$$env" ]; then \
			(cd "$$env" && tofu fmt -check && tofu init -backend=false && tofu validate) || exit 1; \
		fi \
	done
	@echo "==> 2. Linting Helm Charts..."
	@helm lint k8s/charts/datalakehouse
	@echo "==> 3. Verifying Go Exporter Binary..."
	@test -f ./bin/compliance_exporter
	@echo "✅ All CI/CD checks passed successfully!"

inspect: ## Run interactive Medallion data lakehouse inspection and print layer outputs
	@echo "🔍 Running interactive data pipeline inspection..."
	~/.local/share/lakehouse-venv/bin/python scripts/inspect_pipeline.py

test: ## Run full unit test suite across all phases
	@echo "🧪 Running unit tests..."
	python3 -m unittest discover tests

verify-phase1: ## Run automated Phase 1 verification and generate Markdown artifact report
	@echo "🔍 Running automated Phase 1 health check & generating artifact report..."
	python3 scripts/verify_phase1.py

verify-phase3: ## Run automated Phase 3 Zarf packaging verification and generate Markdown artifact report
	@echo "🔍 Running automated Phase 3 Zarf packaging health check & generating artifact report..."
	python3 scripts/verify_phase3.py

verify-phase4: ## Run automated Phase 4 UDS Bundle and Service Mesh verification
	@echo "🔍 Running automated Phase 4 UDS Bundle & Service Mesh health check & generating artifact report..."
	python3 scripts/verify_phase4.py

verify-phase5: ## Run automated Phase 5 Lula OSCAL compliance verification and Go exporter
	@echo "🛡️  Running automated Phase 5 Lula OSCAL compliance verification..."
	python3 scripts/verify_phase5.py

verify-phase6: ## Run automated Phase 6 accreditation artifact generation and verification
	@echo "📜 Running automated Phase 6 accreditation artifact verification..."
	python3 scripts/verify_phase6.py

ato-package: ## Generate complete DoD IL5 ATO Accreditation Package (SSP, SAR, ConMon, POAM)
	@echo "📜 Generating complete DoD IL5 ATO Accreditation Package..."
	python3 scripts/generate_ato_package.py

package: zarf-package ## Build Zarf air-gapped package (.tar.zst)

zarf-package: ## Build Zarf air-gapped package (.tar.zst)
	@echo "📦 Building Zarf package..."
	zarf package create --confirm

zarf-init: ## Initialize Zarf internal registry on target Kubernetes cluster
	@echo "⚙️  Initializing Zarf on target Kubernetes cluster..."
	zarf init --confirm

zarf-deploy: ## Deploy Zarf package to target Kubernetes cluster
	@echo "🚀 Deploying Zarf package to target Kubernetes cluster..."
	@bash scripts/deploy_zarf_package.sh

bundle-create: ## Create UDS bundle archive (.tar.zst)
	@echo "📦 Creating UDS Bundle..."
	uds create . --confirm

bundle-deploy: ## Deploy UDS bundle to target Kubernetes cluster
	@echo "🚀 Deploying UDS Bundle..."
	uds deploy --confirm

deploy: zarf-deploy ## Deploy Data Lakehouse workloads into target K8s cluster

audit: go-build ## Run Lula OSCAL continuous compliance evaluation and Go exporter
	@echo "🛡️  Executing Lula OSCAL validation..."
	@if [ -z "$$KUBECONFIG" ] && [ -f "$$HOME/Projects/devops/repos/homelab-terraform_k8s/terraform/environments/03-k8s-bootstrap/kubeconfig.yaml" ]; then \
		export KUBECONFIG="$$HOME/Projects/devops/repos/homelab-terraform_k8s/terraform/environments/03-k8s-bootstrap/kubeconfig.yaml"; \
	fi; \
	rm -f assessment-results.yaml; \
	lula validate -f oscal-il5.yaml -o assessment-results.yaml
	@echo "📊 Parsing OSCAL findings using Go Exporter..."
	@./bin/compliance_exporter assessment-results.yaml

go-build: ## Build Golang OSCAL compliance exporter binary
	@echo "🐹 Building Go compliance exporter CLI..."
	mkdir -p bin
	go build -o bin/compliance_exporter src/compliance_exporter/main.go

clean: ## Clean up local build artifacts and cache
	@echo "🧹 Cleaning up artifacts..."
	rm -rf bin/ zarf-package-*.tar.zst il5-results.yaml assessment-results.yaml docs/artifacts/
