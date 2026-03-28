# 🚀 AWS Production Deployment Guide

Complete step-by-step guide to deploy this microservices project on AWS using:
**EKS** (Kubernetes) · **ECR** (Container Registry) · **RDS** (MySQL) · **ElastiCache** (Redis) · **MSK** (Kafka) · **Jenkins** (CI/CD)

---

## 📋 Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Prerequisites — What You Need](#2-prerequisites--what-you-need)
3. [Phase 1 — AWS Account Setup](#3-phase-1--aws-account-setup)
4. [Phase 2 — Infrastructure with Terraform](#4-phase-2--infrastructure-with-terraform)
5. [Phase 3 — ECR Repositories](#5-phase-3--ecr-repositories)
6. [Phase 4 — EKS Cluster Setup](#6-phase-4--eks-cluster-setup)
7. [Phase 5 — RDS, Redis & Kafka Configuration](#7-phase-5--rds-redis--kafka-configuration)
8. [Phase 6 — Jenkins Server Setup](#8-phase-6--jenkins-server-setup)
9. [Phase 7 — Jenkins Pipeline Configuration](#9-phase-7--jenkins-pipeline-configuration)
10. [Phase 8 — Kubernetes Deployment](#10-phase-8--kubernetes-deployment)
11. [Phase 9 — Domain & SSL (HTTPS)](#11-phase-9--domain--ssl-https)
12. [Phase 10 — Monitoring](#12-phase-10--monitoring)
13. [Rollback Procedure](#13-rollback-procedure)
14. [Cost Estimate](#14-cost-estimate)
15. [Things You Must Provide](#15-things-you-must-provide)

---

## 1. Architecture Overview

```
Internet
    │
    ▼
Route 53 (DNS)
    │
    ▼
ACM Certificate (SSL/TLS)
    │
    ▼
AWS Application Load Balancer  ◄── AWS ALB Ingress Controller (in EKS)
    │
    ▼
┌───────────────────────────────────────────────────────┐
│                  Amazon EKS Cluster                   │
│                  (3 worker nodes, t3.medium)           │
│                                                       │
│  config-server  →  eureka-server  →  api-gateway      │
│                                          │            │
│          ┌───────────────────────────────┤            │
│          │           │                  │            │
│    user-service  product-service  order-service       │
│          │           │           │      │            │
│          │        redis (cache)   │  notification-svc │
│          └───────────┴───────────┘                   │
└───────────────────────────────────────────────────────┘
    │              │              │
    ▼              ▼              ▼
Amazon RDS     Amazon RDS    Amazon RDS
(user_db)      (product_db)  (order_db)
MySQL 8.0      MySQL 8.0     MySQL 8.0
Multi-AZ       Multi-AZ      Multi-AZ
    
Amazon ElastiCache (Redis) ── Product Service caching
Amazon MSK (Kafka)         ── Order ↔ Notification events
Amazon ECR                 ── Docker image registry (7 repos)
Jenkins on EC2             ── CI/CD pipeline
```

---

## 2. Prerequisites — What You Need

### Tools to install on your local machine

```powershell
# 1. AWS CLI v2
# Download from: https://awscli.amazonaws.com/AWSCLIV2.msi

# 2. Terraform >= 1.6
# Download from: https://developer.hashicorp.com/terraform/downloads

# 3. kubectl
# Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/

# 4. eksctl
# Download from: https://github.com/eksctl-io/eksctl/releases

# 5. Helm 3
# Download from: https://github.com/helm/helm/releases

# Verify all installations
aws --version
terraform --version
kubectl version --client
eksctl version
helm version
```

### AWS Services you need access to

| Service | Purpose |
|---------|---------|
| **EKS** | Kubernetes cluster for all microservices |
| **ECR** | Docker image storage (7 repositories) |
| **RDS MySQL** | 3 separate databases (user, order, product) |
| **ElastiCache** | Redis cache for product-service |
| **MSK** | Kafka for order→notification events |
| **EC2** | Jenkins server |
| **ALB** | Load balancer (via EKS Ingress) |
| **Route 53** | DNS for your domain |
| **ACM** | Free SSL/TLS certificates |
| **IAM** | Roles and policies |
| **VPC** | Private network (auto-created by Terraform) |

---

## 3. Phase 1 — AWS Account Setup

### Step 1.1 — Configure AWS CLI

```bash
# Configure with your AWS Access Key + Secret Key
aws configure

# AWS Access Key ID:     <your-access-key>
# AWS Secret Access Key: <your-secret-key>
# Default region name:   ap-south-1
# Default output format: json

# Verify
aws sts get-caller-identity
```

### Step 1.2 — Create IAM User for Jenkins (CI/CD)

Go to **AWS Console → IAM → Users → Create User**

- Username: `jenkins-cicd`
- Attach these policies:
  - `AmazonEKSClusterPolicy`
  - `AmazonEKSWorkerNodePolicy`
  - `AmazonEC2ContainerRegistryFullAccess`
  - `AmazonRDSFullAccess` *(or read-only if preferred)*
  - Custom inline policy (see below)

**Create inline policy** named `JenkinsCICDPolicy`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
```

- Generate **Access Key** for this user → save it for Jenkins credentials

### Step 1.3 — Create S3 Bucket for Terraform State

> ⚠️ **S3 bucket names must be globally unique across ALL AWS accounts.**
> Replace `<YOUR_AWS_ACCOUNT_ID>` below with your 12-digit AWS Account ID
> (find it at: AWS Console → top-right corner → click your name).
> This makes the name unique to you.

**Run each command one by one in Command Prompt or PowerShell:**

```powershell
# ─── Step A: Create the S3 bucket ─────────────────────────────────────────
# Replace with YOUR 12-digit AWS Account ID
aws s3api create-bucket --bucket microservices-tfstate-392186013048 --region ap-south-1 --create-bucket-configuration LocationConstraint=ap-south-1

# ─── Step B: Enable versioning ────────────────────────────────────────────
aws s3api put-bucket-versioning --bucket microservices-tfstate-392186013048 --versioning-configuration Status=Enabled

# ─── Step C: Enable encryption ────────────────────────────────────────────
aws s3api put-bucket-encryption --bucket microservices-tfstate-392186013048 --server-side-encryption-configuration "{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}"

# ─── Step D: Create DynamoDB table for state locking ──────────────────────
aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region ap-south-1
```

> 📝 **Remember your bucket name!** You'll need to put it in `deploy/terraform/main.tf`
> in the `backend "s3"` block (already there — just update the bucket name).

---

## 4. Phase 2 — Infrastructure with Terraform

All infrastructure is defined in `deploy/terraform/`.

### Step 2.1 — Set your variables

```bash
cd deploy/terraform

# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with real values
# - aws_region
# - project_name
# - eks_cluster_name
# - user_db_password     (strong password!)
# - order_db_password
# - product_db_password
# - jwt_secret           (run: openssl rand -hex 32)
```

### Step 2.2 — Initialize and Apply

```bash
# Initialize (downloads providers, connects to S3 backend)
terraform init

# Preview what will be created (~25 resources)
terraform plan

# Create all AWS infrastructure (takes ~20-30 minutes)
terraform apply
# Type 'yes' when prompted
```

### Step 2.3 — Save the outputs

After `terraform apply` completes, note all outputs:

```bash
terraform output
```

You will get values like:
```
ecr_registry             = "392186013048.dkr.ecr.ap-south-1.amazonaws.com"
eks_cluster_name         = "microservices-eks"
user_db_endpoint         = "jdbc:mysql://microservices-user-db.abc123.ap-south-1.rds.amazonaws.com:3306/user_db"
order_db_endpoint        = "jdbc:mysql://microservices-order-db.abc123.ap-south-1.rds.amazonaws.com:3306/order_db"
product_db_endpoint      = "jdbc:mysql://microservices-product-db.abc123.ap-south-1.rds.amazonaws.com:3306/product_db"
redis_primary_endpoint   = "microservices-redis.abc123.ng.0001.aps1.cache.amazonaws.com"
kafka_bootstrap_brokers  = "b-1.microservices-kafka.abc123.kafka.ap-south-1.amazonaws.com:9092,..."
```

> ⚠️ **Save all these values** — you'll need them in the next steps.

---

## 5. Phase 3 — ECR Repositories

ECR repos are created automatically by Terraform. Verify them:

```bash
aws ecr describe-repositories --region ap-south-1 --query 'repositories[].repositoryName'
```

Expected output:
```json
["microservices/config-server", "microservices/eureka-server", "microservices/api-gateway",
 "microservices/user-service", "microservices/product-service", "microservices/order-service",
 "microservices/notification-service"]
```

### Push images manually (first time, before Jenkins is ready)

```bash
# Set your values
AWS_ACCOUNT_ID="392186013048"
AWS_REGION="ap-south-1"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_BASE="${ECR_REGISTRY}/microservices"

# Authenticate Docker to ECR
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Build and push each service (run from project root)
for svc in config-server eureka-server api-gateway user-service product-service order-service notification-service; do
  docker build -t ${ECR_BASE}/${svc}:latest ./${svc}
  docker push ${ECR_BASE}/${svc}:latest
done
```

---

## 6. Phase 4 — EKS Cluster Setup

### Step 4.1 — Connect kubectl to EKS

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name microservices-eks

# Verify connection
kubectl get nodes
# Should show 3 nodes in Ready state
```

### Step 4.2 — Install AWS Load Balancer Controller

This is **required** for the ALB Ingress to work.

```bash
# Add the EKS chart repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Create IAM service account for the controller
eksctl create iamserviceaccount \
  --cluster=microservices-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy \
  --override-existing-serviceaccounts \
  --approve \
  --region ap-south-1

# Install the controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=microservices-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Verify
kubectl -n kube-system get deployment aws-load-balancer-controller
```

### Step 4.3 — Install Metrics Server (for HPA)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify
kubectl -n kube-system get deployment metrics-server
```

### Step 4.4 — Create monitoring namespace for Zipkin

```bash
kubectl create namespace monitoring

# Deploy Zipkin (optional — for distributed tracing)
kubectl -n monitoring apply -f https://raw.githubusercontent.com/openzipkin/zipkin/master/zipkin-server/src/main/k8s/zipkin.yaml
```

---

## 7. Phase 5 — RDS, Redis & Kafka Configuration

### Step 5.1 — Update platform-config.yaml

Open `deploy/eks/platform-config.yaml` and replace all `REPLACE_WITH_*` placeholders with values from `terraform output`:

```yaml
# Example — replace with YOUR actual terraform output values:
KAFKA_BOOTSTRAP_SERVERS: "b-1.microservices-kafka.abc123.kafka.ap-south-1.amazonaws.com:9092,b-2...."
REDIS_HOST: "microservices-redis.abc123.ng.0001.aps1.cache.amazonaws.com"
USER_DB_URL: "jdbc:mysql://microservices-user-db.abc123.ap-south-1.rds.amazonaws.com:3306/user_db"
ORDER_DB_URL: "jdbc:mysql://microservices-order-db.abc123.ap-south-1.rds.amazonaws.com:3306/order_db"
PRODUCT_DB_URL: "jdbc:mysql://microservices-product-db.abc123.ap-south-1.rds.amazonaws.com:3306/product_db"
```

Also update the **Secret** section with the same passwords used in `terraform.tfvars`:
```yaml
USER_DB_PASSWORD: "your-actual-password"
ORDER_DB_PASSWORD: "your-actual-password"
PRODUCT_DB_PASSWORD: "your-actual-password"
JWT_SECRET: "your-64-char-hex-secret"
```

### Step 5.2 — Apply to Kubernetes

```bash
kubectl apply -f deploy/eks/platform-config.yaml

# Verify
kubectl -n microservices get configmap platform-config -o yaml
kubectl -n microservices get secret platform-secrets
```

### Step 5.3 — Verify RDS connectivity from EKS

```bash
# Run a temporary MySQL client pod inside the cluster
kubectl -n microservices run mysql-test --rm -it \
  --image=mysql:8.0 \
  --env="MYSQL_ROOT_PASSWORD=test" \
  -- bash

# Inside the pod, test connection:
mysql -h microservices-user-db.XXXX.ap-south-1.rds.amazonaws.com \
      -u userservice -p user_db
# Enter the password → should show mysql prompt
exit
```

---

## 8. Phase 6 — Jenkins Server Setup

### Step 6.1 — Launch Jenkins EC2 Instance

**AWS Console → EC2 → Launch Instance:**

| Setting | Value |
|---------|-------|
| **Name** | `jenkins-server` |
| **AMI** | Amazon Linux 2023 |
| **Instance Type** | `t3.medium` (2 vCPU, 4GB RAM) |
| **Key Pair** | Create new or use existing |
| **Security Group** | Allow: SSH (22), HTTP (8080) from your IP |
| **Storage** | 30 GB gp3 |
| **IAM Role** | Create role with ECR + EKS permissions |

### Step 6.2 — Install Jenkins + Docker + Tools

SSH into the EC2 instance and run:

```bash
# Update system
sudo dnf update -y

# Install Java 17
sudo dnf install -y java-17-amazon-corretto

# Add Jenkins repo and install
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo dnf install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Install Docker
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker jenkins   # Allow Jenkins to run Docker
sudo usermod -aG docker ec2-user

# Install Git
sudo dnf install -y git

# Install Maven 3.9
sudo dnf install -y maven

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install eksctl
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz"
tar -xzf eksctl_${PLATFORM}.tar.gz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Restart Jenkins to pick up Docker group
sudo systemctl restart jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 6.3 — Configure Jenkins

1. Open browser: `http://<EC2_PUBLIC_IP>:8080`
2. Paste the initial admin password
3. Click **"Install suggested plugins"**
4. Create admin user
5. Install additional plugins:
   - Go to **Manage Jenkins → Plugins → Available**
   - Search and install:
     - ✅ **Amazon ECR**
     - ✅ **AWS Credentials**
     - ✅ **Pipeline**
     - ✅ **Git**
     - ✅ **Docker Pipeline**
     - ✅ **AnsiColor**
     - ✅ **SonarQube Scanner**
     - ✅ **Slack Notification**

---

## 9. Phase 7 — Jenkins Pipeline Configuration

### Step 7.1 — Add AWS Credentials

**Manage Jenkins → Credentials → System → Global → Add Credentials:**

| Field | Value |
|-------|-------|
| Kind | **AWS Credentials** |
| ID | `aws-jenkins-creds` |
| Access Key ID | `<jenkins-cicd IAM user access key>` |
| Secret Access Key | `<jenkins-cicd IAM user secret key>` |

### Step 7.2 — Add SonarQube Token (optional)

| Field | Value |
|-------|-------|
| Kind | **Secret text** |
| ID | `sonar-token` |
| Secret | `<your sonarqube token>` |

### Step 7.3 — Add Slack Webhook (optional)

| Field | Value |
|-------|-------|
| Kind | **Secret text** |
| ID | `slack-webhook` |
| Secret | `https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK` |

### Step 7.4 — Update Jenkinsfile values

Edit `Jenkinsfile` in the repo — update these 3 lines with your real values:

```groovy
AWS_REGION      = 'ap-south-1'           // ← your region
AWS_ACCOUNT_ID  = '392186013048'          // ← your 12-digit AWS Account ID
EKS_CLUSTER_NAME = 'microservices-eks'   // ← your EKS cluster name
```

### Step 7.5 — Create Jenkins Pipeline Job

1. **New Item** → name: `microservices-pipeline` → type: **Pipeline**
2. Under **Pipeline** section:
   - **Definition:** Pipeline script from SCM
   - **SCM:** Git
   - **Repository URL:** `https://github.com/YOUR_USERNAME/YOUR_REPO.git`
   - **Credentials:** Add your GitHub token
   - **Branch:** `*/main`
   - **Script Path:** `Jenkinsfile`
3. Check **"GitHub hook trigger for GITScm polling"** for auto-trigger
4. **Save**

### Step 7.6 — Setup GitHub Webhook (auto-trigger on push)

In your GitHub repo:
1. **Settings → Webhooks → Add webhook**
2. **Payload URL:** `http://<JENKINS_EC2_IP>:8080/github-webhook/`
3. **Content type:** `application/json`
4. **Events:** Just the push event
5. **Save**

---

## 10. Phase 8 — Kubernetes Deployment

### Step 8.1 — Update microservices.yaml domain

Edit `deploy/eks/microservices.yaml` — update the Ingress host:

```yaml
# Find this section near the bottom:
spec:
  rules:
    - host: api.microservices.example.com   # ← change to your domain
```

### Step 8.2 — First Manual Deployment

```bash
# Connect kubectl to your EKS cluster
aws eks update-kubeconfig --region ap-south-1 --name microservices-eks

# Apply config and secrets
kubectl apply -f deploy/eks/platform-config.yaml

# Replace image placeholder and apply workloads
# Replace YOUR_ACCOUNT_ID below
sed 's|REPLACE_IN_CI|392186013048.dkr.ecr.ap-south-1.amazonaws.com/microservices|g' \
  deploy/eks/microservices.yaml | kubectl apply -f -

# Watch pods come up (takes 3-5 minutes)
kubectl -n microservices get pods -w
```

### Step 8.3 — Verify all pods are running

```bash
kubectl -n microservices get pods
```

Expected output:
```
NAME                                    READY   STATUS    RESTARTS   AGE
config-server-xxx                       1/1     Running   0          3m
eureka-server-xxx                       1/1     Running   0          3m
api-gateway-xxx-1                       1/1     Running   0          2m
api-gateway-xxx-2                       1/1     Running   0          2m
user-service-xxx-1                      1/1     Running   0          2m
user-service-xxx-2                      1/1     Running   0          2m
product-service-xxx-1                   1/1     Running   0          2m
product-service-xxx-2                   1/1     Running   0          2m
order-service-xxx-1                     1/1     Running   0          1m
order-service-xxx-2                     1/1     Running   0          1m
notification-service-xxx                1/1     Running   0          1m
```

### Step 8.4 — Get the ALB DNS name

```bash
kubectl -n microservices get ingress api-gateway-ingress
# NAME                  CLASS   HOSTS                          ADDRESS
# api-gateway-ingress   alb     api.microservices.example.com  k8s-XXX.ap-south-1.elb.amazonaws.com

# Test the API gateway
curl http://k8s-XXX.ap-south-1.elb.amazonaws.com/actuator/health
```

---

## 11. Phase 9 — Domain & SSL (HTTPS)

### Step 9.1 — Request ACM Certificate

```bash
# AWS Console → Certificate Manager → Request certificate
# OR via CLI:
aws acm request-certificate \
  --domain-name "api.yourdomain.com" \
  --validation-method DNS \
  --region ap-south-1

# Complete DNS validation in Route 53 (AWS will show CNAME records to add)
```

### Step 9.2 — Update Ingress for HTTPS

Edit `deploy/eks/microservices.yaml` — update the Ingress annotations:

```yaml
annotations:
  alb.ingress.kubernetes.io/scheme: internet-facing
  alb.ingress.kubernetes.io/target-type: ip
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80,"HTTPS":443}]'
  alb.ingress.kubernetes.io/ssl-redirect: '443'
  alb.ingress.kubernetes.io/certificate-arn: 'arn:aws:acm:ap-south-1:392186013048:certificate/YOUR-CERT-ARN'
  alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
```

### Step 9.3 — Point your domain to ALB

In **Route 53 → Hosted Zone → Create Record:**

| Field | Value |
|-------|-------|
| Record name | `api` |
| Record type | `A` |
| Alias | Yes |
| Alias target | ALB DNS name (`k8s-XXX.ap-south-1.elb.amazonaws.com`) |

---

## 12. Phase 10 — Monitoring

### CloudWatch Container Insights

```bash
# Enable CloudWatch Container Insights for EKS
aws eks create-addon \
  --cluster-name microservices-eks \
  --addon-name amazon-cloudwatch-observability \
  --region ap-south-1
```

### Access Dashboards

| Dashboard | URL |
|-----------|-----|
| **Eureka** (service registry) | `http://<ALB>/eureka/` (via api-gateway) |
| **Zipkin** (tracing) | Port-forward: `kubectl -n monitoring port-forward svc/zipkin 9411:9411` |
| **AWS CloudWatch** | AWS Console → CloudWatch → Container Insights |
| **Jenkins** | `http://<EC2_IP>:8080` |

---

## 13. Rollback Procedure

### Roll back a specific service

```bash
# Check rollout history
kubectl -n microservices rollout history deployment/user-service

# Roll back to previous version
kubectl -n microservices rollout undo deployment/user-service

# Roll back to specific revision
kubectl -n microservices rollout undo deployment/user-service --to-revision=3
```

### Roll back all services

```bash
for svc in config-server eureka-server api-gateway user-service product-service order-service notification-service; do
  kubectl -n microservices rollout undo deployment/${svc}
done
```

---

## 14. Cost Estimate (ap-south-1 / Mumbai)

| Service | Config | Est. Monthly Cost |
|---------|--------|-------------------|
| EKS Cluster | 1 cluster | ~$72 |
| EC2 Worker Nodes | 3x t3.medium | ~$90 |
| RDS MySQL | 3x db.t3.micro Multi-AZ | ~$90 |
| ElastiCache | 2x cache.t3.micro | ~$30 |
| MSK Kafka | 3x kafka.t3.small | ~$150 |
| EC2 Jenkins | 1x t3.medium | ~$30 |
| ALB | 1x | ~$20 |
| ECR | 7 repos | ~$5 |
| Data Transfer | ~100GB | ~$10 |
| **Total** | | **~$497/month** |

> 💡 **Cost saving tips:**
> - Use **Spot Instances** for worker nodes (save ~70%)
> - Stop Jenkins EC2 when not running builds
> - Use `db.t3.micro` Single-AZ for dev/staging
> - Use single-node MSK for non-prod

---

## 15. Things You Must Provide

Before starting, collect these values:

| Item | Where to get it | Used in |
|------|----------------|---------|
| **AWS Account ID** (12 digits) | AWS Console top-right corner | Jenkinsfile, Terraform |
| **AWS Region** | Choose your preferred region | All files |
| **Domain name** | Buy from Route 53 or any registrar | Ingress, ACM |
| **Strong DB passwords** (3x) | Generate yourself | terraform.tfvars |
| **JWT secret** (64 hex chars) | `openssl rand -hex 32` | terraform.tfvars |
| **GitHub repo URL** | Your Git repository | Jenkins job |
| **GitHub personal token** | GitHub → Settings → Developer Settings | Jenkins credentials |
| **Slack webhook** (optional) | Slack → Apps → Incoming Webhooks | Jenkins credentials |

### Generate secrets right now

```bash
# Generate JWT secret
openssl rand -hex 32

# Generate strong password
openssl rand -base64 16
```

---

## 📁 Files Created for Deployment

```
deploy/
├── eks/
│   ├── platform-config.yaml    ← K8s ConfigMap + Secret (update placeholders)
│   ├── microservices.yaml      ← All K8s Deployments, Services, HPA, Ingress
│   └── README.md
└── terraform/
    ├── main.tf                 ← VPC, EKS, ECR, RDS, Redis, MSK
    ├── variables.tf            ← All input variables
    ├── outputs.tf              ← Values to copy into platform-config.yaml
    └── terraform.tfvars.example ← Copy to terraform.tfvars and fill in
```

---

## ✅ Deployment Checklist

- [ ] AWS CLI configured with correct account
- [ ] S3 bucket created for Terraform state
- [ ] DynamoDB table created for state locking
- [ ] `terraform.tfvars` filled in with real values
- [ ] `terraform apply` completed successfully
- [ ] All `terraform output` values saved
- [ ] `platform-config.yaml` updated with real endpoints
- [ ] `kubectl` connected to EKS cluster
- [ ] AWS Load Balancer Controller installed
- [ ] Metrics Server installed
- [ ] `platform-config.yaml` applied to Kubernetes
- [ ] First deployment successful — all pods Running
- [ ] Jenkins EC2 launched and configured
- [ ] Jenkins credentials added (aws-jenkins-creds, sonar-token, slack-webhook)
- [ ] `Jenkinsfile` updated with AWS_ACCOUNT_ID and EKS_CLUSTER_NAME
- [ ] Jenkins pipeline job created and tested
- [ ] GitHub webhook configured for auto-trigger
- [ ] Domain DNS pointing to ALB
- [ ] SSL certificate issued and applied
- [ ] Health checks passing: `/actuator/health`

