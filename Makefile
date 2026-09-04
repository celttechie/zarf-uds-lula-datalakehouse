.PHONY: help ci dev-sandbox dev-cluster dev-destroy-all aws-k3s-up aws-k3s-down aws-eks-up aws-eks-down bundle-deploy-aws-k3s bundle-deploy-aws-eks verify-phase1 test inspect verify-phase3 verify-phase4 verify-phase5 verify-phase6 ato-package package deploy audit go-build clean

help: ## Display available Makefile target commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

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

# ---------------------------------------------------------------------------------------------------------------------
# Phase 1: Local KVM Infrastructure Targets
# ---------------------------------------------------------------------------------------------------------------------

dev-sandbox: ## Provision Phase 1 Stage 1 Layer 1 Nested Hypervisor VM (Libvirt/KVM)
	@echo "🚀 Provisioning Stage 1 Nested Sandbox VM..."
	cd terraform/environments/01-nested-sandbox && tofu init && tofu apply -auto-approve

dev-cluster: ## Provision Phase 1 Stage 2 Kubernetes Cluster Node inside Sandbox (Libvirt/KVM)
	@echo "🚀 Provisioning Stage 2 K8s Cluster Node..."
	cd terraform/environments/02-k8s-cluster && tofu init && tofu apply -auto-approve

dev-destroy-all: ## Destroy all local Phase 1 Terraform infrastructure in reverse order
	@echo "🧹 Destroying Stage 2 K8s Cluster Node..."
	cd terraform/environments/02-k8s-cluster && tofu destroy -auto-approve || true
	@echo "🧹 Destroying Stage 1 Nested Sandbox VM..."
	cd terraform/environments/01-nested-sandbox && tofu destroy -auto-approve || true

# ---------------------------------------------------------------------------------------------------------------------
# Cloud: AWS Infrastructure Targets (Option 2: EC2 K3s & Option 3: EKS)
# ---------------------------------------------------------------------------------------------------------------------

aws-k3s-up: ## Provision AWS EC2 Spot + K3s environment (~$0.04/hr, $0 control plane fee)
	@echo "🚀 Provisioning AWS EC2 Spot K3s sandbox..."
	cd terraform/environments/03-aws-ec2-k3s && tofu init && tofu apply -auto-approve
	@bash scripts/fetch_aws_kubeconfig.sh k3s

aws-k3s-down: ## Destroy AWS EC2 Spot + K3s environment immediately to prevent spend
	@echo "🧹 Destroying AWS EC2 Spot K3s sandbox..."
	cd terraform/environments/03-aws-ec2-k3s && tofu destroy -auto-approve

aws-eks-up: ## Provision AWS Managed EKS Cluster + Spot Node Group
	@echo "🚀 Provisioning AWS Managed EKS Cluster..."
	cd terraform/environments/04-aws-eks && tofu init && tofu apply -auto-approve
	@bash scripts/fetch_aws_kubeconfig.sh eks

aws-eks-down: ## Destroy AWS Managed EKS Cluster immediately to prevent ongoing control plane spend
	@echo "🧹 Destroying AWS Managed EKS Cluster..."
	cd terraform/environments/04-aws-eks && tofu destroy -auto-approve

bundle-deploy-aws-k3s: ## Deploy UDS Bundle to AWS EC2 K3s with runtime config overlay
	@echo "🚀 Deploying UDS Bundle to AWS EC2 K3s..."
	uds deploy --config uds-config-aws-k3s.yaml --confirm

bundle-deploy-aws-eks: ## Deploy UDS Bundle to AWS Managed EKS with gp3 storage class overlay
	@echo "🚀 Deploying UDS Bundle to AWS Managed EKS..."
	uds deploy --config uds-config-aws-eks.yaml --confirm

# ---------------------------------------------------------------------------------------------------------------------
# Phase Verification Targets
# ---------------------------------------------------------------------------------------------------------------------

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
