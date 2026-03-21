# EKS Deployment and Jenkins CI/CD

This folder contains Kubernetes manifests used by the root `Jenkinsfile` to deploy services to Amazon EKS.

## Included files

- `platform-config.yaml`: namespace, shared non-secret config (`ConfigMap`), and initial secret template (`Secret`).
- `microservices.yaml`: `Deployment`, `Service`, `HorizontalPodAutoscaler`, and ALB `Ingress` resources.

## Services covered

- `config-server`
- `eureka-server`
- `api-gateway`
- `user-service`
- `product-service`
- `order-service`

## Prerequisites

- EKS cluster and worker nodes are ready.
- AWS Load Balancer Controller is installed in the cluster.
- ECR repositories exist for each service.
- Jenkins node has Docker, AWS CLI, and kubectl installed.
- Jenkins credential `aws-jenkins-creds` exists (AWS access key and secret).

## Required updates before first deployment

1. In `platform-config.yaml`, replace placeholder endpoints with your real:
   - RDS hosts
   - Redis endpoint
   - Kafka bootstrap servers
   - Zipkin endpoint
2. Replace placeholder secret values in `platform-config.yaml`.
3. In root `Jenkinsfile`, set:
   - `AWS_REGION`
   - `EKS_CLUSTER_NAME`
   - `ECR_REGISTRY`

## Manual deployment (optional)

```bash
kubectl apply -f deploy/eks/platform-config.yaml
kubectl apply -f deploy/eks/microservices.yaml
```

## Notes

- Ingress host is `api.microservices.example.com`; update it to your domain.
- Current secrets are plain Kubernetes Secret values for bootstrap only.
- For production, prefer AWS Secrets Manager + External Secrets Operator.

