#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Deploy Keycloak + PostgreSQL + Kong Ingress via Pulumi (Ubuntu 26 / LXD)
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

cd "${ROOT_DIR}"

echo -e "\033[1;36m==============================================\033[0m"
echo -e "\033[1;36m  Deploying via Pulumi (pulumi up)            \033[0m"
echo -e "\033[1;36m==============================================\033[0m"

# Ensure Pulumi is installed
if ! command -v pulumi >/dev/null 2>&1; then
    echo -e "\033[1;31m[ERROR] Pulumi CLI is not installed or not in PATH.\033[0m"
    echo "Install it using: curl -fsSL https://get.pulumi.com | sh"
    exit 1
fi

# Select or create the dev stack
STACK="${1:-dev}"
echo -e "\n\033[1;33m--> Selecting stack '${STACK}'...\033[0m"
pulumi stack select "${STACK}" 2>/dev/null || pulumi stack init "${STACK}"

# Preview and Deploy
echo -e "\n\033[1;33m--> Running pulumi up...\033[0m"
pulumi up --yes

echo -e "\n\033[1;32m--> Deployment complete!\033[0m"
echo -e "\n\033[1;35m[Outputs]\033[0m"
pulumi stack output
