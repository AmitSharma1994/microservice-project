#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test all microservice APIs locally after docker-compose is up.
.DESCRIPTION
    Runs curl commands against each service to verify they are responding.
    Run this AFTER .\start-local.ps1 and waiting ~90 seconds.
#>

$ErrorActionPreference = "Continue"
$GATEWAY = "http://localhost:8080"

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "   Microservices API Smoke Test" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

function Test-Endpoint {
    param([string]$Name, [string]$Url, [string]$Method = "GET", [string]$Body)
    Write-Host "`n--- $Name ---" -ForegroundColor Yellow
    Write-Host "  $Method $Url" -ForegroundColor DarkGray
    try {
        $params = @{ Uri = $Url; Method = $Method; ContentType = "application/json"; TimeoutSec = 10 }
        if ($Body) { $params.Body = $Body }
        $response = Invoke-RestMethod @params
        Write-Host "  ✅ SUCCESS" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White
    } catch {
        Write-Host "  ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- Health Checks ---
Write-Host "`n========== HEALTH CHECKS ==========" -ForegroundColor Magenta
Test-Endpoint "Config Server Health"    "http://localhost:8888/actuator/health"
Test-Endpoint "Eureka Server Health"    "http://localhost:8761/actuator/health"
Test-Endpoint "API Gateway Health"      "$GATEWAY/actuator/health"
Test-Endpoint "User Service Health"     "http://localhost:8081/actuator/health"
Test-Endpoint "Product Service Health"  "http://localhost:8083/actuator/health"
Test-Endpoint "Order Service Health"    "http://localhost:8082/actuator/health"
Test-Endpoint "Notification Status"     "http://localhost:8084/api/notifications/status"

# --- User Service ---
Write-Host "`n========== USER SERVICE ==========" -ForegroundColor Magenta
$userBody = '{"username":"testuser","email":"test@example.com","password":"Test@1234","role":"USER"}'
Test-Endpoint "Register User" "http://localhost:8081/api/users/register" "POST" $userBody
Test-Endpoint "Get All Users" "http://localhost:8081/api/users"

# --- Product Service ---
Write-Host "`n========== PRODUCT SERVICE ==========" -ForegroundColor Magenta
$productBody = '{"name":"Laptop","description":"High-end laptop","price":1299.99,"stockQuantity":50}'
Test-Endpoint "Create Product" "http://localhost:8083/api/products" "POST" $productBody
Test-Endpoint "Get All Products" "http://localhost:8083/api/products"

# --- Order Service ---
Write-Host "`n========== ORDER SERVICE ==========" -ForegroundColor Magenta
$orderBody = '{"userId":1,"items":[{"productId":1,"quantity":2}],"paymentMethod":"CREDIT_CARD"}'
Test-Endpoint "Create Order" "http://localhost:8082/api/orders" "POST" $orderBody
Test-Endpoint "Get All Orders" "http://localhost:8082/api/orders"

# --- Via API Gateway ---
Write-Host "`n========== API GATEWAY ROUTES ==========" -ForegroundColor Magenta
Test-Endpoint "Gateway -> Users"    "$GATEWAY/api/users"
Test-Endpoint "Gateway -> Products" "$GATEWAY/api/products"
Test-Endpoint "Gateway -> Orders"   "$GATEWAY/api/orders"

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "   Smoke Test Complete" -ForegroundColor Cyan
Write-Host "=============================================`n" -ForegroundColor Cyan

