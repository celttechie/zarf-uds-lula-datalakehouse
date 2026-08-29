.PHONY: help dev-sandbox dev-cluster dev-destroy-all verify-phase1 test inspect verify-phase3 verify-phase4 package deploy audit go-build clean

help: ## Display available Makefile target commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

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
