#!/usr/bin/env bash
# =============================================================================
# deploy-terraform.sh – Deploy the platform logs DCR/DCRA using Terraform
# =============================================================================
# Usage:
#   chmod +x scripts/deploy-terraform.sh
#   ./scripts/deploy-terraform.sh [--var-file <path>] [--destroy]
#
# The script will:
#   1. Initialize Terraform (terraform init)
#   2. Validate the configuration (terraform validate)
#   3. Show a plan (terraform plan)
#   4. Apply (terraform apply -auto-approve)
#
# Pass --destroy to destroy previously deployed resources instead.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="${SCRIPT_DIR}/../terraform"

# ── Defaults ──────────────────────────────────────────────────────────────────
VAR_FILE="${TF_DIR}/terraform.tfvars"
DESTROY=false

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --var-file) VAR_FILE="$2"; shift 2 ;;
    --destroy)  DESTROY=true;  shift   ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ── Prerequisites check ───────────────────────────────────────────────────────
command -v terraform >/dev/null 2>&1 || { echo "ERROR: Terraform CLI is not installed."; exit 1; }

# ── Init ──────────────────────────────────────────────────────────────────────
echo "==> Initializing Terraform in '${TF_DIR}'..."
terraform -chdir="${TF_DIR}" init -upgrade

# ── Validate ──────────────────────────────────────────────────────────────────
echo "==> Validating Terraform configuration..."
terraform -chdir="${TF_DIR}" validate

if [[ "${DESTROY}" == "true" ]]; then
  echo "==> Destroying Terraform-managed resources..."
  terraform -chdir="${TF_DIR}" destroy \
    -var-file="${VAR_FILE}" \
    -auto-approve
  echo ""
  echo "✅  Destroy completed successfully."
else
  # ── Plan ────────────────────────────────────────────────────────────────────
  echo "==> Creating Terraform plan..."
  terraform -chdir="${TF_DIR}" plan \
    -var-file="${VAR_FILE}" \
    -out="${TF_DIR}/tfplan"

  # ── Apply ───────────────────────────────────────────────────────────────────
  echo "==> Applying Terraform plan..."
  terraform -chdir="${TF_DIR}" apply "${TF_DIR}/tfplan"
  echo ""
  echo "✅  Deployment completed successfully."
fi
