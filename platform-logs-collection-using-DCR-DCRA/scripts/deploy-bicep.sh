#!/usr/bin/env bash
# =============================================================================
# deploy-bicep.sh – Deploy the platform logs DCR/DCRA using Bicep templates
# =============================================================================
# Usage:
#   chmod +x scripts/deploy-bicep.sh
#   ./scripts/deploy-bicep.sh \
#     --subscription    <subscription-id> \
#     --resource-group  <resource-group-name> \
#     --location        <azure-region> \
#     --parameters-file <path-to-bicepparam>  # optional, defaults to bicep/main.bicepparam
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_DIR="${SCRIPT_DIR}/../bicep"

# ── Defaults ──────────────────────────────────────────────────────────────────
PARAMETERS_FILE="${BICEP_DIR}/main.bicepparam"
DEPLOYMENT_NAME="platform-logs-dcr-$(date +%Y%m%d%H%M%S)"

# ── Argument parsing ──────────────────────────────────────────────────────────
SUBSCRIPTION_ID=""
RESOURCE_GROUP=""
LOCATION="eastus"

print_usage() {
  echo "Usage: $0 --subscription <id> --resource-group <name> [--location <region>] [--parameters-file <path>]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription)    SUBSCRIPTION_ID="$2"; shift 2 ;;
    --resource-group)  RESOURCE_GROUP="$2";  shift 2 ;;
    --location)        LOCATION="$2";        shift 2 ;;
    --parameters-file) PARAMETERS_FILE="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; print_usage ;;
  esac
done

[[ -z "${SUBSCRIPTION_ID}" ]] && { echo "ERROR: --subscription is required."; print_usage; }
[[ -z "${RESOURCE_GROUP}" ]]  && { echo "ERROR: --resource-group is required."; print_usage; }

# ── Prerequisites check ───────────────────────────────────────────────────────
command -v az >/dev/null 2>&1 || { echo "ERROR: Azure CLI (az) is not installed."; exit 1; }

echo "==> Setting active subscription to ${SUBSCRIPTION_ID}..."
az account set --subscription "${SUBSCRIPTION_ID}"

# ── Ensure resource group exists ──────────────────────────────────────────────
echo "==> Ensuring resource group '${RESOURCE_GROUP}' exists in '${LOCATION}'..."
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --output none

# ── Deploy ────────────────────────────────────────────────────────────────────
echo "==> Deploying Bicep template '${BICEP_DIR}/main.bicep'..."
echo "    Parameters file : ${PARAMETERS_FILE}"
echo "    Deployment name : ${DEPLOYMENT_NAME}"

az deployment group create \
  --name "${DEPLOYMENT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "${BICEP_DIR}/main.bicep" \
  --parameters "${PARAMETERS_FILE}" \
  --output json

echo ""
echo "✅  Deployment '${DEPLOYMENT_NAME}' completed successfully."
