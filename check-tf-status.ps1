# Check the status of terraform apply
$resultFile = "D:\WSMicroservice\terraform-apply-result.txt"
$statusFile = "D:\WSMicroservice\microservice-project\tf-status.txt"

$output = @()
$output += "Check time: $(Get-Date)"
$output += "Result file exists: $(Test-Path $resultFile)"

$tfProcess = Get-Process -Name terraform -ErrorAction SilentlyContinue
if ($tfProcess) {
    $output += "Terraform process running: YES (PID: $($tfProcess.Id))"
} else {
    $output += "Terraform process running: NO"
}

if (Test-Path $resultFile) {
    $output += "--- RESULT FILE CONTENT (last 50 lines) ---"
    $output += (Get-Content $resultFile | Select-Object -Last 50)
}

# Also check terraform state
Set-Location D:\WSMicroservice\microservice-project\deploy\terraform
$stateList = & D:\Softwares\terraform\terraform.exe state list 2>&1 | Out-String
$output += "--- TERRAFORM STATE ---"
$output += $stateList

$output | Out-File -FilePath $statusFile -Encoding utf8

