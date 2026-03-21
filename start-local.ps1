#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start all microservices locally using Docker Compose.
.DESCRIPTION
    1. Builds all Maven modules (skipping tests for speed)
    2. Starts all containers via docker-compose (infrastructure + services)
    3. Prints service URLs for testing
#>

param(
    [switch]$SkipBuild,
    [switch]$InfraOnly
)

$ErrorActionPreference = "Stop"
$ROOT = $PSScriptRoot

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "   Microservices Local Startup" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# ------- Step 1: Maven Build -------
if (-not $SkipBuild) {
    Write-Host "`n[1/3] Building all Maven modules..." -ForegroundColor Yellow
    Push-Location $ROOT
    try {
        mvn clean package -DskipTests -T 2C
        if ($LASTEXITCODE -ne 0) { throw "Maven build failed" }
        Write-Host "   Maven build SUCCEEDED" -ForegroundColor Green
    } finally {
        Pop-Location
    }
} else {
    Write-Host "`n[1/3] Skipping Maven build (--SkipBuild flag)" -ForegroundColor DarkGray
}

# ------- Step 2: Docker Compose -------
if ($InfraOnly) {
    Write-Host "`n[2/3] Starting INFRASTRUCTURE only..." -ForegroundColor Yellow
    docker-compose -f "$ROOT\docker-compose.yml" up -d `
        mysql-user mysql-order mysql-product redis zookeeper kafka zipkin
} else {
    Write-Host "`n[2/3] Starting ALL services via Docker Compose..." -ForegroundColor Yellow
    docker-compose -f "$ROOT\docker-compose.yml" up --build -d
}

if ($LASTEXITCODE -ne 0) { throw "Docker Compose failed" }
Write-Host "   Docker Compose started" -ForegroundColor Green

# ------- Step 3: Print URLs -------
Write-Host "`n[3/3] Service URLs:" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Cyan

$services = @(
    @{ Name = "Config Server";        URL = "http://localhost:8888/actuator/health" },
    @{ Name = "Eureka Dashboard";     URL = "http://localhost:8761" },
    @{ Name = "API Gateway";          URL = "http://localhost:8080/actuator/health" },
    @{ Name = "User Service";         URL = "http://localhost:8081/swagger-ui.html" },
    @{ Name = "Order Service";        URL = "http://localhost:8082/swagger-ui.html" },
    @{ Name = "Product Service";      URL = "http://localhost:8083/swagger-ui.html" },
    @{ Name = "Notification Service"; URL = "http://localhost:8084/api/notifications/status" },
    @{ Name = "Zipkin Tracing";       URL = "http://localhost:9411" }
)

foreach ($svc in $services) {
    Write-Host ("  {0,-24} -> {1}" -f $svc.Name, $svc.URL) -ForegroundColor White
}

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "  TIP: Wait 60-90s for all services to register with Eureka." -ForegroundColor DarkGray
Write-Host "  Run .\stop-local.ps1 to stop everything." -ForegroundColor DarkGray
Write-Host "  Run .\start-local.ps1 -SkipBuild to restart without rebuilding." -ForegroundColor DarkGray
Write-Host "  Run .\start-local.ps1 -InfraOnly to start only infrastructure." -ForegroundColor DarkGray
Write-Host "=============================================`n" -ForegroundColor Cyan

