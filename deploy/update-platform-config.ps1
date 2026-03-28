###############################################################################
# update-platform-config.ps1
#
# Fetches all Terraform output values and auto-fills every placeholder in
# deploy/eks/platform-config.yaml.
#
# Prerequisites:
#   1. AWS credentials must be valid (run `aws configure` or re-export keys)
#   2. Terraform must be initialised (terraform init already done)
#
# Usage:
#   cd D:\WSMicroservice\microservice-project\deploy
#   .\update-platform-config.ps1
###############################################################################

$SCRIPT_DIR  = Split-Path -Parent $MyInvocation.MyCommand.Path
$TF_DIR      = Join-Path $SCRIPT_DIR "terraform"
$CONFIG_FILE = Join-Path $SCRIPT_DIR "eks\platform-config.yaml"

Write-Host "==> Fetching Terraform outputs from $TF_DIR ..." -ForegroundColor Cyan

Push-Location $TF_DIR
try {
    # Run terraform output, capture stdout only (ignore stderr warnings)
    $oldPref = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $tfOutput = terraform output -json 2>$null
    $ErrorActionPreference = $oldPref

    if ($LASTEXITCODE -ne 0 -or -not $tfOutput) {
        Write-Host "ERROR: terraform output failed. Check your AWS credentials or run 'terraform init'." -ForegroundColor Red
        Pop-Location
        exit 1
    }
    $outputs = $tfOutput | ConvertFrom-Json
} catch {
    Write-Host "ERROR: Failed to parse terraform output: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

# ── Extract values ──────────────────────────────────────────────────────────
$kafkaBrokers    = $outputs.kafka_bootstrap_brokers.value
$redisEndpoint   = $outputs.redis_primary_endpoint.value
$userDbUrl       = $outputs.user_db_endpoint.value
$orderDbUrl      = $outputs.order_db_endpoint.value
$productDbUrl    = $outputs.product_db_endpoint.value

# Passwords come from terraform.tfvars — read them directly
$tfVars = Get-Content (Join-Path $TF_DIR "terraform.tfvars") -Raw
$userPwd    = ([regex]'user_db_password\s*=\s*"([^"]+)"').Match($tfVars).Groups[1].Value
$orderPwd   = ([regex]'order_db_password\s*=\s*"([^"]+)"').Match($tfVars).Groups[1].Value
$productPwd = ([regex]'product_db_password\s*=\s*"([^"]+)"').Match($tfVars).Groups[1].Value
$jwtSecret  = ([regex]'jwt_secret\s*=\s*"([^"]+)"').Match($tfVars).Groups[1].Value

Write-Host ""
Write-Host "==> Values extracted:" -ForegroundColor Cyan
Write-Host "  KAFKA_BOOTSTRAP_SERVERS : $kafkaBrokers"
Write-Host "  REDIS_HOST              : $redisEndpoint"
Write-Host "  USER_DB_URL             : $userDbUrl"
Write-Host "  ORDER_DB_URL            : $orderDbUrl"
Write-Host "  PRODUCT_DB_URL          : $productDbUrl"
Write-Host "  USER_DB_PASSWORD        : (from tfvars)"
Write-Host "  ORDER_DB_PASSWORD       : (from tfvars)"
Write-Host "  PRODUCT_DB_PASSWORD     : (from tfvars)"
Write-Host "  JWT_SECRET              : $jwtSecret"

# ── Replace placeholders in platform-config.yaml ────────────────────────────
Write-Host ""
Write-Host "==> Updating $CONFIG_FILE ..." -ForegroundColor Cyan

$content = Get-Content $CONFIG_FILE -Raw

$content = $content -replace 'REPLACE_WITH_MSK_BOOTSTRAP_BROKERS',       $kafkaBrokers
$content = $content -replace 'REPLACE_WITH_ELASTICACHE_PRIMARY_ENDPOINT', $redisEndpoint
$content = $content -replace 'REPLACE_WITH_USER_RDS_JDBC_URL',            $userDbUrl
$content = $content -replace 'REPLACE_WITH_ORDER_RDS_JDBC_URL',           $orderDbUrl
$content = $content -replace 'REPLACE_WITH_PRODUCT_RDS_JDBC_URL',         $productDbUrl
$content = $content -replace 'REPLACE_WITH_USER_DB_PASSWORD',             $userPwd
$content = $content -replace 'REPLACE_WITH_ORDER_DB_PASSWORD',            $orderPwd
$content = $content -replace 'REPLACE_WITH_PRODUCT_DB_PASSWORD',          $productPwd
$content = $content -replace 'REPLACE_WITH_JWT_SECRET_64_CHAR_HEX',       $jwtSecret

Set-Content $CONFIG_FILE -Value $content -NoNewline

Write-Host "  Done! platform-config.yaml has been updated." -ForegroundColor Green
Write-Host ""
Write-Host "==> Next step: apply it to your cluster" -ForegroundColor Yellow
Write-Host "    kubectl apply -f deploy/eks/platform-config.yaml"

