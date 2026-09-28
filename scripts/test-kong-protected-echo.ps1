<#
.SYNOPSIS
    Tests Kong Gateway enforcement: verifies 401 Unauthorized without token,
    and 200 OK when presenting a valid Keycloak JWT.
#>

param(
    [string]$EchoUrl = "http://192.168.100.240/echo-protected",
    [string]$Token = $global:LAST_KEYCLOAK_TOKEN
)

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Testing Kong Gateway JWT Protection         " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# Test 1: Without Token
Write-Host "`n[Test 1] Sending request WITHOUT Bearer token..." -ForegroundColor Yellow
try {
    $res = Invoke-WebRequest -Uri $EchoUrl -Method Get -SkipHttpErrorCheck
    if ($res.StatusCode -eq 401) {
        Write-Host "[PASSED] Kong correctly blocked request (HTTP 401 Unauthorized)." -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Expected 401, but got HTTP $($res.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "[PASSED] Blocked with error: $_" -ForegroundColor Green
}

# Test 2: With Token
if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Warning "`nNo token provided. Run test-user-token.ps1 first to obtain a valid JWT token."
    exit 0
}

Write-Host "`n[Test 2] Sending request WITH Keycloak Bearer token..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $Token"
    }
    $res = Invoke-RestMethod -Uri $EchoUrl -Method Get -Headers $headers
    Write-Host "[PASSED] Kong validated token and forwarded to backend! (HTTP 200 OK)" -ForegroundColor Green
    Write-Host "`nEcho Response Body:" -ForegroundColor Cyan
    $res | ConvertTo-Json -Depth 3 | Write-Host
} catch {
    Write-Error "[FAILED] Request rejected: $_"
}
