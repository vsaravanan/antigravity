#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Test Machine-to-Machine (M2M) OAuth2 Client Credentials Grant
# -----------------------------------------------------------------------------

BASE_URL="${BASE_URL:-http://keycloak.192.168.100.240.nip.io}"
REALM="${REALM:-lab-realm}"
CLIENT_ID="${CLIENT_ID:-backend-service}"
CLIENT_SECRET="${1:-${CLIENT_SECRET:-}}"

if [[ -z "${CLIENT_SECRET}" ]]; then
    echo -e "\033[1;31m[ERROR] ClientSecret is required.\033[0m"
    echo "Usage: $0 <client-secret>"
    echo "   or: CLIENT_SECRET=<secret> $0"
    exit 1
fi

TOKEN_ENDPOINT="${BASE_URL}/realms/${REALM}/protocol/openid-connect/token"
echo -e "\033[1;36mRequesting M2M Token from: ${TOKEN_ENDPOINT}\033[0m"

RESPONSE=$(curl -s -X POST "${TOKEN_ENDPOINT}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=${CLIENT_ID}" \
    -d "client_secret=${CLIENT_SECRET}" \
    -d "grant_type=client_credentials")

if echo "${RESPONSE}" | grep -q "access_token"; then
    echo -e "\n\033[1;32m[SUCCESS] Token Received!\033[0m"
    if command -v jq >/dev/null 2>&1; then
        echo "${RESPONSE}" | jq '{token_type, expires_in, access_token: (.access_token[:50] + "...")}'
    else
        echo "${RESPONSE}"
    fi
    
    # Save token for downstream scripts
    mkdir -p /tmp/keycloak
    echo "${RESPONSE}" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4 > /tmp/keycloak/token.txt
    echo -e "\nToken saved to /tmp/keycloak/token.txt"
else
    echo -e "\n\033[1;31m[FAILED] Error response:\033[0m"
    echo "${RESPONSE}"
    exit 1
fi
