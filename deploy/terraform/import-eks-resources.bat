@echo off
REM ─────────────────────────────────────────────────────────────────────────
REM  Import EKS-related and remaining AWS resources into Terraform state
REM  Run from: deploy/terraform/  directory
REM ─────────────────────────────────────────────────────────────────────────
echo.
echo === Importing ElastiCache Subnet Group ===
terraform import aws_elasticache_subnet_group.main microservices-redis-subnet

echo.
echo === Importing OIDC Provider ===
terraform import "module.eks.aws_iam_openid_connect_provider.oidc_provider[0]" "arn:aws:iam::392186013048:oidc-provider/oidc.eks.ap-south-1.amazonaws.com/id/3DD9460A620831FCF3F6C7BFF2FFDB75"

echo.
echo === Importing CloudWatch Log Group ===
terraform import "module.eks.aws_cloudwatch_log_group.this[0]" "/aws/eks/microservices-eks/cluster"

echo.
echo === Importing KMS Alias ===
terraform import "module.eks.module.kms.aws_kms_alias.this[\"cluster\"]" "alias/eks/microservices-eks"

echo.
echo === Importing EKS Access Entry for cluster_creator ===
terraform import "module.eks.aws_eks_access_entry.this[\"cluster_creator\"]" "microservices-eks:arn:aws:iam::392186013048:user/AmitSharma"

echo.
echo === Importing EKS Access Policy Association ===
terraform import "module.eks.aws_eks_access_policy_association.this[\"cluster_creator_admin\"]" "microservices-eks#arn:aws:iam::392186013048:user/AmitSharma#arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

echo.
echo === Import complete! Run: terraform plan ===

