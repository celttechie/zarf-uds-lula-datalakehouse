#!/usr/bin/env bash
# Helper script to fetch kubeconfig from either AWS EC2 K3s or AWS Managed EKS
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-k3s}"

mkdir -p "${REPO_ROOT}/.kube"

if [[ "${TARGET}" == "k3s" ]]; then
  ENV_DIR="${REPO_ROOT}/terraform/environments/03-aws-ec2-k3s"
  if [[ ! -d "${ENV_DIR}/.terraform" ]]; then
    echo "❌ Error: Terraform environment at ${ENV_DIR} has not been applied."
    exit 1
  fi

  echo "🔍 Retrieving EC2 Spot public IP from Terraform outputs..."
  PUBLIC_IP=$(cd "${ENV_DIR}" && tofu output -raw public_ip 2>/dev/null || terraform output -raw public_ip)
  SSH_KEY="${ENV_DIR}/.terraform/id_ed25519"
  OUTPUT_KUBECONFIG="${REPO_ROOT}/.kube/config-aws-k3s.yaml"

  echo "📥 Waiting for K3s to be ready on ubuntu@${PUBLIC_IP}..."
  MAX_RETRIES=30
  RETRY_COUNT=0
  until ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "ubuntu@${PUBLIC_IP}" 'sudo test -f /etc/rancher/k3s/k3s.yaml' 2>/dev/null; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [[ ${RETRY_COUNT} -ge ${MAX_RETRIES} ]]; then
      echo "❌ Timeout waiting for K3s installation on ${PUBLIC_IP}."
      exit 1
    fi
    echo "   ⏳ Waiting for K3s bootstrap to complete (${RETRY_COUNT}/${MAX_RETRIES})..."
    sleep 5
  done

  echo "📥 Fetching K3s kubeconfig from ubuntu@${PUBLIC_IP}..."
  ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new "ubuntu@${PUBLIC_IP}" 'sudo cat /etc/rancher/k3s/k3s.yaml' | \
    sed "s/127.0.0.1/${PUBLIC_IP}/g" > "${OUTPUT_KUBECONFIG}"

  chmod 0600 "${OUTPUT_KUBECONFIG}"
  echo "✅ Kubeconfig successfully written to ${OUTPUT_KUBECONFIG}"
  echo "👉 To activate, run:"
  echo "   export KUBECONFIG=${OUTPUT_KUBECONFIG}"

elif [[ "${TARGET}" == "eks" ]]; then
  ENV_DIR="${REPO_ROOT}/terraform/environments/04-aws-eks"
  if [[ ! -d "${ENV_DIR}/.terraform" ]]; then
    echo "❌ Error: Terraform environment at ${ENV_DIR} has not been applied."
    exit 1
  fi

  if ! command -v aws &>/dev/null; then
    echo "❌ Error: AWS CLI ('aws') is required to configure EKS kubeconfig."
    echo "   Please install the AWS CLI or run the update-kubeconfig command manually."
    exit 1
  fi

  CLUSTER_NAME=$(cd "${ENV_DIR}" && tofu output -raw cluster_name 2>/dev/null || terraform output -raw cluster_name)
  OUTPUT_KUBECONFIG="${REPO_ROOT}/.kube/config-aws-eks.yaml"

  echo "📥 Fetching AWS EKS kubeconfig for cluster '${CLUSTER_NAME}'..."
  aws eks update-kubeconfig --name "${CLUSTER_NAME}" --kubeconfig "${OUTPUT_KUBECONFIG}"

  echo "✅ Kubeconfig successfully written to ${OUTPUT_KUBECONFIG}"
  echo "👉 To activate, run:"
  echo "   export KUBECONFIG=${OUTPUT_KUBECONFIG}"

else
  echo "Usage: $0 [k3s|eks]"
  exit 1
fi
