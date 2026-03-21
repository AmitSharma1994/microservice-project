#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Stop all microservices and infrastructure.
.DESCRIPTION
    Tears down every container started by docker-compose and optionally removes volumes.
#>

param(
    [switch]$RemoveVolumes
)

$ROOT = $PSScriptRoot

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "   Stopping Microservices..." -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

if ($RemoveVolumes) {
    Write-Host "  Removing containers AND volumes..." -ForegroundColor Yellow
    docker-compose -f "$ROOT\docker-compose.yml" down -v
} else {
    Write-Host "  Removing containers (volumes preserved)..." -ForegroundColor Yellow
    docker-compose -f "$ROOT\docker-compose.yml" down
}

Write-Host "`n  All services stopped." -ForegroundColor Green
Write-Host "  To also delete database volumes: .\stop-local.ps1 -RemoveVolumes" -ForegroundColor DarkGray
Write-Host "=============================================`n" -ForegroundColor Cyan

