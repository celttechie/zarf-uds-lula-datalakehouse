#!/usr/bin/env bash
# Deploy Zarf Air-Gapped Package to Target Kubernetes Cluster
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_FILE="$(ls -1 "${REPO_ROOT}"/zarf-package-il5-data-lakehouse-*.tar.zst 2>/dev/null | head -n 1 || true)"

if [[ -z "${PACKAGE_FILE}" ]]; then
  echo "📦 No Zarf package archive found. Building package first..."
  (cd "${REPO_ROOT}" && zarf package create --confirm)
  PACKAGE_FILE="$(ls -1 "${REPO_ROOT}"/zarf-package-il5-data-lakehouse-*.tar.zst | head -n 1)"
fi

echo "🚀 Deploying Zarf Package: $(basename "${PACKAGE_FILE}")..."
zarf package deploy "${PACKAGE_FILE}" --confirm

echo "✅ Zarf Package Deployment Complete!"
kubectl get pods,svc,jobs -n datalakehouse -o wide || true
