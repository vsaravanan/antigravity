#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Deploy Keycloak + PostgreSQL + Kong Ingress on Kubernetes (Ubuntu 26 / LXD)
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="${SCRIPT_DIR}/../k8s"

echo -e "\033[1;36m==============================================\033[0m"
echo -e "\033[1;36m  Deploying Keycloak + Kong Stack             \033[0m"
echo -e "\033[1;36m==============================================\033[0m"

files=(
    "00-namespace.yaml"
    "01-postgres.yaml"
    "02-keycloak.yaml"
    "03-kong-ingress.yaml"
)

for file in "${files[@]}"; do
    echo -e "\n\033[1;33m--> Applying ${file}...\033[0m"
    kubectl apply -f "${K8S_DIR}/${file}"
done

echo -e "\n\033[1;36mWaiting for PostgreSQL to be ready...\033[0m"
kubectl rollout status deployment/postgres -n keycloak --timeout=120s

echo -e "\n\033[1;36mWaiting for Keycloak (Quarkus) to be ready...\033[0m"
kubectl rollout status deployment/keycloak -n keycloak --timeout=180s

echo -e "\n\033[1;32m--> Keycloak is successfully deployed and ready!\033[0m"
echo -e "\n\033[1;35m[Endpoint Info]\033[0m"
echo -e "Admin URL:      http://keycloak.192.168.100.240.nip.io/admin"
echo -e "Admin User:     admin"
echo -e "Admin Password: AdminMasterPassword123!"
