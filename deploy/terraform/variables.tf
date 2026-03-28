# variables.tf — Input variables for all Terraform modules

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short project name used as prefix for all resources"
  type        = string
  default     = "microservices"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "microservices-eks"
}

variable "user_db_password" {
  description = "Password for the User Service RDS MySQL instance"
  type        = string
  sensitive   = true
}

variable "order_db_password" {
  description = "Password for the Order Service RDS MySQL instance"
  type        = string
  sensitive   = true
}

variable "product_db_password" {
  description = "Password for the Product Service RDS MySQL instance"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT signing secret (hex/base64 string)"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "microservices"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

