# EKS Deployment — Kubernetes Manifests

This folder contains Kubernetes manifests used by the root `Jenkinsfile` to deploy all microservices to Amazon EKS.

> 📖 **Full step-by-step guide:** See [`AWS_DEPLOYMENT_GUIDE.md`](../../AWS_DEPLOYMENT_GUIDE.md) in the project root.

---

## Files in this folder

| File | Purpose |
|------|---------|
| `platform-config.yaml` | Namespace + ConfigMap (non-sensitive config) + Secret template |
| `microservices.yaml` | Deployments, Services, HPAs, ALB Ingress for all 7 services |

## Services deployed

| Service | Replicas | Port |
|---------|----------|------|
| `config-server` | 1 | 8888 |
| `eureka-server` | 1 | 8761 |
| `api-gateway` | 2 | 8080 |
| `user-service` | 2 | 8081 |
| `product-service` | 2 | 8083 |
| `order-service` | 2 | 8082 |
| `notification-service` | 1 | 8084 |

## Quick start (manual deployment)

```bash
# 1. Connect kubectl to your EKS cluster
aws eks update-kubeconfig --region ap-south-1 --name microservices-eks

# 2. Fill in platform-config.yaml placeholders, then apply
kubectl apply -f deploy/eks/platform-config.yaml

# 3. Replace REPLACE_IN_CI with your ECR base URL, then apply workloads
sed 's|REPLACE_IN_CI|YOUR_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/microservices|g' \
  deploy/eks/microservices.yaml | kubectl apply -f -

# 4. Watch pods come up
kubectl -n microservices get pods -w
```

## Placeholders to replace in platform-config.yaml

Get values from `terraform output` after running `deploy/terraform/`:

- `REPLACE_WITH_MSK_BOOTSTRAP_BROKERS`
- `REPLACE_WITH_ELASTICACHE_PRIMARY_ENDPOINT`
- `REPLACE_WITH_USER_RDS_JDBC_URL`
- `REPLACE_WITH_ORDER_RDS_JDBC_URL`
- `REPLACE_WITH_PRODUCT_RDS_JDBC_URL`
- `REPLACE_WITH_USER_DB_PASSWORD`
- `REPLACE_WITH_ORDER_DB_PASSWORD`
- `REPLACE_WITH_PRODUCT_DB_PASSWORD`
- `REPLACE_WITH_JWT_SECRET_64_CHAR_HEX`

Also update the Ingress host in `microservices.yaml`:
- `api.microservices.example.com` → your actual domain

## Infrastructure prerequisites

- EKS cluster running (provisioned by `deploy/terraform/main.tf`)
- AWS Load Balancer Controller installed in the cluster
- ECR repositories created (provisioned by Terraform)
- Metrics Server installed (for HPA auto-scaling)
- Jenkins EC2 with AWS CLI + kubectl + Docker installed

## Notes

- For production secrets, use **AWS Secrets Manager + External Secrets Operator**
  instead of plain Kubernetes Secrets.
  See: https://external-secrets.io/latest/provider/aws-secrets-manager/
