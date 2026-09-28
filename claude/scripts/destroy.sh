#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Teardown Keycloak + PostgreSQL + Kong Ingress via Pulumi (pulumi destroy)
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

cd "${ROOT_DIR}"

echo -e "\033[1;31m==============================================\033[0m"
echo -e "\033[1;31m  Tearing down via Pulumi (pulumi destroy)    \033[0m"
echo -e "\033[1;31m==============================================\033[0m"

STACK="${1:-dev}"
pulumi stack select "${STACK}" 2>/dev/null || true

echo -e "\n\033[1;33m--> Destroying stack resources...\033[0m"
pulumi destroy --yes

echo -e "\n\033[1;32m--> Stack '${STACK}' successfully destroyed.\033[0m"
