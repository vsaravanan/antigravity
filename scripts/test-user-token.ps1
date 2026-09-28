<#
.SYNOPSIS
    Tests End-User Authentication (Resource Owner Password / Direct Grant) & decodes the JWT claims.
#>

param(
    [string]$BaseUrl = "http://keycloak.192.168.100.240.nip.io",
    [string]$Realm = "lab-realm",
    [string]$ClientId = "demo-app",
    [string]$Username = "alice",
    [string]$Password = "Password123!"
)

$tokenEndpoint = "$BaseUrl/realms/$Realm/protocol/openid-connect/token"
Write-Host "Authenticating User '$Username' against realm '$Realm'..." -ForegroundColor Cyan

$body = @{
    client_id  = $ClientId
    username   = $Username
    password   = $Password
    grant_type = "password"
}

try {
    $response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    Write-Host "`n[SUCCESS] User authenticated successfully!" -ForegroundColor Green
    Write-Host "Token Type:    $($response.token_type)"
    Write-Host "Expires In:    $($response.expires_in)s"
    Write-Host "Refresh Token: Present ($($response.refresh_token.Substring(0, 30))...)"
    
    # Decode JWT Payload
    $parts = $response.access_token.Split('.')
    if ($parts.Length -ge 2) {
        $payload = $parts[1]
        # Pad base64 string
        $mod4 = $payload.Length % 4
        if ($mod4 -gt 0) { $payload += "=" * (4 - $mod4) }
        $decodedBytes = [System.Convert]::FromBase64String($payload.Replace('-', '+').Replace('_', '/'))
        $decodedJson = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
        
        Write-Host "`n[Decoded JWT Payload]:" -ForegroundColor Yellow
        $decodedJson | ConvertFrom-Json | ConvertTo-Json -Depth 5 | Write-Host
    }

    $global:LAST_KEYCLOAK_TOKEN = $response.access_token
} catch {
    Write-Error "Failed to authenticate user: $_"
}
