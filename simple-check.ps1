# Simple check
"Check time: $(Get-Date)" | Out-File -FilePath D:\WSMicroservice\microservice-project\simple-check.txt -Encoding utf8
"Result file exists: $(Test-Path 'D:\WSMicroservice\terraform-apply-result.txt')" | Out-File -FilePath D:\WSMicroservice\microservice-project\simple-check.txt -Append -Encoding utf8

$proc = Get-Process -Name terraform -ErrorAction SilentlyContinue
if ($proc) {
    "Terraform PID: $($proc.Id) Started: $($proc.StartTime)" | Out-File -FilePath D:\WSMicroservice\microservice-project\simple-check.txt -Append -Encoding utf8
} else {
    "Terraform NOT running" | Out-File -FilePath D:\WSMicroservice\microservice-project\simple-check.txt -Append -Encoding utf8
}

$files = Get-ChildItem D:\WSMicroservice\*.txt -ErrorAction SilentlyContinue
"Files in D:\WSMicroservice: $($files.Name -join ', ')" | Out-File -FilePath D:\WSMicroservice\microservice-project\simple-check.txt -Append -Encoding utf8

