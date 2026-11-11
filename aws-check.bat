@echo off
echo STARTING > D:\WSMicroservice\microservice-project\aws-check.txt

echo --- ECR Repos --- >> D:\WSMicroservice\microservice-project\aws-check.txt
aws ecr describe-repositories --region ap-south-1 --query "repositories[].repositoryName" --output text >> D:\WSMicroservice\microservice-project\aws-check.txt 2>&1

echo --- EKS Clusters --- >> D:\WSMicroservice\microservice-project\aws-check.txt
aws eks list-clusters --region ap-south-1 --output text >> D:\WSMicroservice\microservice-project\aws-check.txt 2>&1

echo --- EKS Node Groups --- >> D:\WSMicroservice\microservice-project\aws-check.txt
aws eks list-nodegroups --cluster-name microservices-eks --region ap-south-1 --output text >> D:\WSMicroservice\microservice-project\aws-check.txt 2>&1

echo --- RDS Instances --- >> D:\WSMicroservice\microservice-project\aws-check.txt
aws rds describe-db-instances --region ap-south-1 --query "DBInstances[].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Endpoint:Endpoint.Address}" --output table >> D:\WSMicroservice\microservice-project\aws-check.txt 2>&1

echo --- ElastiCache --- >> D:\WSMicroservice\microservice-project\aws-check.txt
aws elasticache describe-replication-groups --region ap-south-1 --query "ReplicationGroups[].{ID:ReplicationGroupId,Status:Status}" --output table >> D:\WSMicroservice\microservice-project\aws-check.txt 2>&1

echo --- MSK Kafka --- >> D:\WSMicroservice\microservice-project\aws-check.txt
aws kafka list-clusters --region ap-south-1 --query "ClusterInfoList[].{Name:ClusterName,State:State}" --output table >> D:\WSMicroservice\microservice-project\aws-check.txt 2>&1

echo --- Terraform Process --- >> D:\WSMicroservice\microservice-project\aws-check.txt
tasklist /fi "imagename eq terraform.exe" >> D:\WSMicroservice\microservice-project\aws-check.txt 2>&1

echo ---ALL CHECKS DONE--- >> D:\WSMicroservice\microservice-project\aws-check.txt

