#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Test User Authentication (Resource Owner Password Grant) & Decode JWT
# -----------------------------------------------------------------------------

BASE_URL="${BASE_URL:-http://keycloak.192.168.100.240.nip.io}"
REALM="${REALM:-lab-realm}"
CLIENT_ID="${CLIENT_ID:-demo-app}"
USERNAME="${1:-alice}"
PASSWORD="${2:-Password123!}"

TOKEN_ENDPOINT="${BASE_URL}/realms/${REALM}/protocol/openid-connect/token"
echo -e "\033[1;36mAuthenticating User '${USERNAME}' against realm '${REALM}'...\033[0m"

RESPONSE=$(curl -s -X POST "${TOKEN_ENDPOINT}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=${CLIENT_ID}" \
    -d "username=${USERNAME}" \
    -d "password=${PASSWORD}" \
    -d "grant_type=password")

if echo "${RESPONSE}" | grep -q "access_token"; then
    echo -e "\n\033[1;32m[SUCCESS] User authenticated successfully!\033[0m"

    mkdir -p /tmp/keycloak
    ACCESS_TOKEN=$(echo "${RESPONSE}" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
    echo "${ACCESS_TOKEN}" > /tmp/keycloak/token.txt
    echo -e "Access token saved to /tmp/keycloak/token.txt"

    echo -e "\n\033[1;33m[Decoded JWT Payload]:\033[0m"
    PAYLOAD_B64=$(echo "${ACCESS_TOKEN}" | cut -d'.' -f2)
    # Add base64 padding if needed
    PAD=$(( (4 - ${#PAYLOAD_B64} % 4) % 4 ))
    if [[ $PAD -gt 0 ]]; then
        PAYLOAD_B64="${PAYLOAD_B64}$(printf '=%.0s' $(seq 1 $PAD))"
    fi
    
    DECODED=$(echo "${PAYLOAD_B64}" | tr '_-' '/+' | base64 -d 2>/dev/null || true)
    if command -v jq >/dev/null 2>&1; then
        echo "${DECODED}" | jq .
    else
        echo "${DECODED}"
    fi
else
    echo -e "\n\033[1;31m[FAILED] Authentication failed:\033[0m"
    echo "${RESPONSE}"
    exit 1
fi
