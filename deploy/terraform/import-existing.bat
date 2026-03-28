@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  Import existing AWS resources into Terraform state
REM  Run from: deploy/terraform/  directory
REM ─────────────────────────────────────────────────────────────────────────
echo.
echo === Importing ECR Repositories ===
terraform import "aws_ecr_repository.services[\"api-gateway\"]" "microservices/api-gateway"
terraform import "aws_ecr_repository.services[\"config-server\"]" "microservices/config-server"
terraform import "aws_ecr_repository.services[\"eureka-server\"]" "microservices/eureka-server"
terraform import "aws_ecr_repository.services[\"notification-service\"]" "microservices/notification-service"
terraform import "aws_ecr_repository.services[\"order-service\"]" "microservices/order-service"
terraform import "aws_ecr_repository.services[\"product-service\"]" "microservices/product-service"
terraform import "aws_ecr_repository.services[\"user-service\"]" "microservices/user-service"

echo.
echo === Importing MSK Kafka Cluster ===
terraform import aws_msk_cluster.kafka "arn:aws:kafka:ap-south-1:392186013048:cluster/microservices-kafka/98e98f1e-11ed-4548-80be-9ba54e0b892b-2"

echo.
echo === Importing ElastiCache Redis ===
terraform import aws_elasticache_replication_group.redis "microservices-redis"

echo.
echo === Import complete! Run: terraform plan ===

