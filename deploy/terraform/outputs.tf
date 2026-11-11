# outputs.tf — Key values printed after `terraform apply`
# Use these values to fill platform-config.yaml and the Jenkinsfile

output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_registry" {
  description = "ECR registry base URL  (use in Jenkinsfile ECR_REGISTRY)"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_repo_urls" {
  description = "Full ECR URL per service"
  value       = { for k, v in aws_ecr_repository.services : k => v.repository_url }
}

output "user_db_endpoint" {
  description = "RDS endpoint for user-service  → USER_DB_URL"
  value       = "jdbc:mysql://${aws_db_instance.user_db.address}:3306/user_db"
}

output "order_db_endpoint" {
  description = "RDS endpoint for order-service  → ORDER_DB_URL"
  value       = "jdbc:mysql://${aws_db_instance.order_db.address}:3306/order_db"
}

output "product_db_endpoint" {
  description = "RDS endpoint for product-service → PRODUCT_DB_URL"
  value       = "jdbc:mysql://${aws_db_instance.product_db.address}:3306/product_db"
}

output "redis_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint → REDIS_HOST"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "kafka_bootstrap_brokers" {
  description = "MSK Kafka bootstrap brokers → KAFKA_BOOTSTRAP_SERVERS"
  value       = aws_msk_cluster.kafka.bootstrap_brokers
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

# Required data source for ECR output
data "aws_caller_identity" "current" {}

