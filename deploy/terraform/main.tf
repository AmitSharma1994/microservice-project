##############################################################
# main.tf — Root Terraform entry point
# Provisions: VPC, EKS, RDS (3 instances), ElastiCache Redis,
#             MSK Kafka, ECR repos, and IAM roles
##############################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }

  # Store state in S3 — create the bucket first (see AWS_DEPLOYMENT_GUIDE.md Step 1.3)
  # ⚠️ Replace the bucket name below with YOUR unique bucket name:
  #    microservices-tfstate-<YOUR_AWS_ACCOUNT_ID>
  backend "s3" {
    bucket         = "microservices-tfstate-392186013048" # This is the bucket you created
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── VPC ──────────────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true    # save costs — one NAT gateway shared by all AZs
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required by AWS Load Balancer Controller
  public_subnet_tags = {
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }

  tags = var.common_tags
}

# ─── EKS ──────────────────────────────────────────────────
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.eks_cluster_name
  cluster_version = "1.35"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  # Grant the IAM principal that creates the cluster full admin access
  # This fixes the "doesn't have access to Kubernetes objects" console banner
  enable_cluster_creator_admin_permissions = true

  # ── EKS Auto Mode ─────────────────────────────────────────────────────────
  # This cluster was created with EKS Auto Mode — AWS manages compute automatically.
  # compute_config, elastic_load_balancing, and block_storage must all match.
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose", "system"]
  }

  # NOTE: No eks_managed_node_groups needed — Auto Mode provides built-in
  # node pools (general-purpose + system).  AWS automatically scales EC2
  # capacity based on pending pod requests.

  # Enable OIDC for IAM Roles for Service Accounts (IRSA)
  enable_irsa = true

  tags = var.common_tags
}

# ─── ECR Repositories ─────────────────────────────────────
locals {
  services = [
    "config-server",
    "eureka-server",
    "api-gateway",
    "user-service",
    "product-service",
    "order-service",
    "notification-service"
  ]
}

resource "aws_ecr_repository" "services" {
  for_each             = toset(local.services)
  name                 = "${var.project_name}/${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.common_tags
}

resource "aws_ecr_lifecycle_policy" "keep_last_10" {
  for_each   = toset(local.services)
  repository = aws_ecr_repository.services[each.key].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# ─── RDS Subnet Group ─────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
  tags       = var.common_tags
}

resource "aws_security_group" "rds" {
  name   = "${var.project_name}-rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

# ─── RDS — User DB ────────────────────────────────────────
resource "aws_db_instance" "user_db" {
  identifier           = "${var.project_name}-user-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = "user_db"
  username             = "userservice"
  password             = var.user_db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot     = true
  multi_az                = false
  storage_encrypted       = false   # free-tier restriction: encryption not available
  backup_retention_period = 0
  tags                    = var.common_tags
}

# ─── RDS — Order DB ───────────────────────────────────────
resource "aws_db_instance" "order_db" {
  identifier           = "${var.project_name}-order-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = "order_db"
  username             = "orderservice"
  password             = var.order_db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot     = true
  multi_az                = false
  storage_encrypted       = false   # free-tier restriction: encryption not available
  backup_retention_period = 0
  tags                    = var.common_tags
}

# ─── RDS — Product DB ─────────────────────────────────────
resource "aws_db_instance" "product_db" {
  identifier           = "${var.project_name}-product-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = "product_db"
  username             = "productservice"
  password             = var.product_db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot     = true
  multi_az                = false
  storage_encrypted       = false   # free-tier restriction: encryption not available
  backup_retention_period = 0
  tags                    = var.common_tags
}

# ─── ElastiCache Redis ────────────────────────────────────
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "redis" {
  name   = "${var.project_name}-redis-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-redis"
  description          = "Redis cluster for product service caching"
  node_type            = "cache.t3.micro"
  num_cache_clusters   = 2
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false   # set true and add auth token for stricter security
  automatic_failover_enabled = true
  tags                 = var.common_tags
}

# ─── Amazon MSK (Kafka) ───────────────────────────────────
resource "aws_security_group" "msk" {
  name   = "${var.project_name}-msk-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

resource "aws_msk_cluster" "kafka" {
  cluster_name           = "${var.project_name}-kafka"
  kafka_version          = "3.5.1"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    client_subnets  = module.vpc.private_subnets
    security_groups = [aws_security_group.msk.id]

    storage_info {
      ebs_storage_info {
        volume_size = 20
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT"
      in_cluster    = true
    }
  }

  tags = var.common_tags
}

