<#
.SYNOPSIS
    Tests Machine-to-Machine (M2M) OAuth2 Client Credentials grant via Keycloak.
#>

param(
    [string]$BaseUrl = "http://keycloak.192.168.100.240.nip.io",
    [string]$Realm = "lab-realm",
    [string]$ClientId = "backend-service",
    [string]$ClientSecret = ""
)

if ([string]::IsNullOrWhiteSpace($ClientSecret)) {
    Write-Warning "No ClientSecret provided. Please provide -ClientSecret <secret> from Keycloak Admin Console."
    exit 1
}

$tokenEndpoint = "$BaseUrl/realms/$Realm/protocol/openid-connect/token"
Write-Host "Requesting M2M Token from: $tokenEndpoint" -ForegroundColor Cyan

$body = @{
    client_id     = $ClientId
    client_secret = $ClientSecret
    grant_type    = "client_credentials"
}

try {
    $response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    Write-Host "`n[SUCCESS] Token Received!" -ForegroundColor Green
    Write-Host "Token Type: $($response.token_type)"
    Write-Host "Expires In: $($response.expires_in) seconds"
    Write-Host "`nAccess Token preview:" -ForegroundColor Yellow
    Write-Host "$($response.access_token.Substring(0, 50))..."
    
    # Export for other scripts
    $global:LAST_KEYCLOAK_TOKEN = $response.access_token
} catch {
    Write-Error "Failed to obtain token: $_"
}
