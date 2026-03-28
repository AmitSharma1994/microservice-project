@echo off
echo Check Time: %date% %time% > D:\WSMicroservice\microservice-project\tf-check.txt
if exist D:\WSMicroservice\terraform-apply-result.txt (
    echo Result file EXISTS >> D:\WSMicroservice\microservice-project\tf-check.txt
    type D:\WSMicroservice\terraform-apply-result.txt >> D:\WSMicroservice\microservice-project\tf-check.txt
) else (
    echo Result file NOT FOUND >> D:\WSMicroservice\microservice-project\tf-check.txt
)
tasklist /fi "imagename eq terraform.exe" >> D:\WSMicroservice\microservice-project\tf-check.txt
dir D:\WSMicroservice\*.txt >> D:\WSMicroservice\microservice-project\tf-check.txt 2>&1
echo ---DONE--- >> D:\WSMicroservice\microservice-project\tf-check.txt

