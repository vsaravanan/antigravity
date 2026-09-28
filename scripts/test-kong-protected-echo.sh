#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Test Kong Gateway JWT Protection on Echo Service
# Verifies 401 Unauthorized without token, and 200 OK with Keycloak Bearer token.
# -----------------------------------------------------------------------------

ECHO_URL="${1:-http://192.168.100.240/echo-protected}"
TOKEN="${2:-}"

if [[ -z "${TOKEN}" ]] && [[ -f /tmp/keycloak/token.txt ]]; then
    TOKEN=$(cat /tmp/keycloak/token.txt)
fi

echo -e "\033[1;36m==============================================\033[0m"
echo -e "\033[1;36m  Testing Kong Gateway JWT Protection         \033[0m"
echo -e "\033[1;36m==============================================\033[0m"

TEMP_RES="/tmp/echo_response.txt"

# Test 1: Without Token
echo -e "\n\033[1;33m[Test 1] Sending request WITHOUT Bearer token...\033[0m"
HTTP_CODE=$(curl -s -o "${TEMP_RES}" -w "%{http_code}" "${ECHO_URL}" || true)

if [[ "${HTTP_CODE}" == "401" ]]; then
    echo -e "\033[1;32m[PASSED] Kong correctly blocked request (HTTP 401 Unauthorized).\033[0m"
else
    echo -e "\033[1;31m[WARNING] Expected 401, but got HTTP ${HTTP_CODE}\033[0m"
    cat "${TEMP_RES}"
fi

# Test 2: With Token
if [[ -z "${TOKEN}" ]]; then
    echo -e "\n\033[1;33m[SKIP] No token provided. Run ./scripts/test-user-token.sh first.\033[0m"
    exit 0
fi

echo -e "\n\033[1;33m[Test 2] Sending request WITH Keycloak Bearer token...\033[0m"
HTTP_CODE=$(curl -s -o "${TEMP_RES}" -w "%{http_code}" \
    -H "Authorization: Bearer ${TOKEN}" \
    "${ECHO_URL}" || true)

if [[ "${HTTP_CODE}" == "200" ]]; then
    echo -e "\033[1;32m[PASSED] Kong validated token and forwarded to backend! (HTTP 200 OK)\033[0m"
    echo -e "\n\033[1;36mEcho Response Body:\033[0m"
    if command -v jq >/dev/null 2>&1; then
        cat "${TEMP_RES}" | jq . 2>/dev/null || cat "${TEMP_RES}"
    else
        cat "${TEMP_RES}"
    fi
    echo ""
else
    echo -e "\033[1;31m[FAILED] Request returned HTTP ${HTTP_CODE}:\033[0m"
    cat "${TEMP_RES}"
    echo ""
    exit 1
fi
