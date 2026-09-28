<#
.SYNOPSIS
    Deploys PostgreSQL, Keycloak, and Kong Ingress onto the Kubernetes cluster.
#>

[CmdletBinding()]
param(
    [string]$KubeconfigPath = ""
)

$ErrorActionPreference = "Stop"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Deploying Keycloak + Kong Stack             " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

$k8sDir = Join-Path $PSScriptRoot "..\k8s"

$files = @(
    "00-namespace.yaml",
    "01-postgres.yaml",
    "02-keycloak.yaml",
    "03-kong-ingress.yaml"
)

foreach ($file in $files) {
    $fullPath = Join-Path $k8sDir $file
    Write-Host "`n--> Applying $file..." -ForegroundColor Yellow
    kubectl apply -f $fullPath
}

Write-Host "`nWaiting for PostgreSQL to be ready..." -ForegroundColor Cyan
kubectl rollout status deployment/postgres -n keycloak --timeout=120s

Write-Host "`nWaiting for Keycloak (Quarkus) to be ready..." -ForegroundColor Cyan
kubectl rollout status deployment/keycloak -n keycloak --timeout=180s

Write-Host "`n--> Keycloak is ready!" -ForegroundColor Green
Write-Host "`n[Endpoint Info]" -ForegroundColor Magenta
Write-Host "Admin URL: http://keycloak.192.168.100.240.nip.io/admin" -ForegroundColor White
Write-Host "Admin User: admin" -ForegroundColor White
Write-Host "Admin Password: AdminMasterPassword123!" -ForegroundColor White
