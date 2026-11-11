# 🚀 Deployment Continuation Guide
## Complete Steps to Deploy Microservices on AWS EKS

> **Current Status (March 23, 2026):** Terraform has partially provisioned infrastructure.
> Resources already created: VPC, EKS Cluster, ECR Repos, Security Groups, IAM Roles, KMS Key, ElastiCache Redis.
> Resources still needed: 3× RDS MySQL, MSK Kafka, EKS Node Group.

---

## Step 1: Complete Terraform Apply

Open a **new PowerShell window** (outside IDE — important!) and run:

```powershell
# Navigate to terraform directory
cd D:\WSMicroservice\microservice-project\deploy\terraform

# First, update IAM policy in AWS (if you haven't added iam:CreatePolicy permission)
# Go to AWS Console → IAM → Users → AmitSharma → Policies → Edit the terraform policy
# Add these actions: iam:CreatePolicy, iam:DeletePolicy, iam:GetPolicy, iam:GetPolicyVersion,
# iam:ListPolicyVersions, iam:CreateServiceLinkedRole
# OR use the updated file: deploy/iam-policy-terraform.json

# Clear any stale state lock
terraform force-unlock -force $(terraform state pull 2>$null | ConvertFrom-Json | Select-Object -ExpandProperty lineage)
# If the above fails, manually clear DynamoDB:
aws dynamodb delete-item `
    --table-name terraform-state-lock `
    --key '{"LockID":{"S":"microservices-tfstate-123456789012/prod/terraform.tfstate"}}' `
    --region ap-south-1

# Run terraform apply
terraform apply -auto-approve
```

**⏱ Expected duration: 20-30 minutes** (MSK Kafka is the slowest ~25 min)

Wait until you see:
```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
```

---

## Step 2: Capture Terraform Outputs

After successful apply, run:

```powershell
cd D:\WSMicroservice\microservice-project\deploy\terraform

# Get all outputs
terraform output

# Save individual values (you'll need these)
terraform output eks_cluster_name
terraform output ecr_registry
terraform output user_db_endpoint
terraform output order_db_endpoint
terraform output product_db_endpoint
terraform output redis_primary_endpoint
terraform output kafka_bootstrap_brokers
```

**Copy these values** — you need them for the next steps.

---

## Step 3: Configure kubectl for EKS

```powershell
# Update kubeconfig to connect to EKS cluster
aws eks update-kubeconfig --region ap-south-1 --name microservices-eks

# Verify connection
kubectl get nodes
# You should see 3 nodes (t3.medium) in Ready state
```

---

## Step 4: Update platform-config.yaml with Real Values

Edit `deploy/eks/platform-config.yaml` and replace ALL placeholders:

| Placeholder | Replace With | Source |
|---|---|---|
| `REPLACE_WITH_MSK_BOOTSTRAP_BROKERS` | `terraform output kafka_bootstrap_brokers` | MSK |
| `REPLACE_WITH_ELASTICACHE_PRIMARY_ENDPOINT` | `terraform output redis_primary_endpoint` | Redis |
| `REPLACE_WITH_USER_RDS_JDBC_URL` | `terraform output user_db_endpoint` | RDS |
| `REPLACE_WITH_ORDER_RDS_JDBC_URL` | `terraform output order_db_endpoint` | RDS |
| `REPLACE_WITH_PRODUCT_RDS_JDBC_URL` | `terraform output product_db_endpoint` | RDS |
| `REPLACE_WITH_USER_DB_PASSWORD` | `UserDB@Prod2026!Secure` | terraform.tfvars |
| `REPLACE_WITH_ORDER_DB_PASSWORD` | `OrderDB@Prod2026!Secure` | terraform.tfvars |
| `REPLACE_WITH_PRODUCT_DB_PASSWORD` | `ProductDB@Prod2026!Secure` | terraform.tfvars |
| `REPLACE_WITH_JWT_SECRET_64_CHAR_HEX` | `5ef87580cce51b97ba7f9c74b0e6fb12d7e8ff0f6eb42d044a043b9a6b681e6f` | terraform.tfvars |

Apply the config:
```powershell
kubectl apply -f deploy/eks/platform-config.yaml
```

---

## Step 5: Build & Push Docker Images to ECR

```powershell
# Set variables
$AWS_ACCOUNT_ID = "392186013048"
$AWS_REGION = "ap-south-1"
$ECR_REGISTRY = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
$TAG = "1.0.0"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build all services (from project root)
cd D:\WSMicroservice\microservice-project

# Build JARs first
mvn clean package -DskipTests

# Build and push Docker images for each service
$services = @("config-server", "eureka-server", "api-gateway", "user-service", "product-service", "order-service", "notification-service")

foreach ($svc in $services) {
    Write-Host "=== Building and pushing $svc ===" -ForegroundColor Green
    
    # Build Docker image
    docker build -t "$ECR_REGISTRY/microservices/$($svc):$TAG" $svc
    docker tag "$ECR_REGISTRY/microservices/$($svc):$TAG" "$ECR_REGISTRY/microservices/$($svc):latest"
    
    # Push to ECR
    docker push "$ECR_REGISTRY/microservices/$($svc):$TAG"
    docker push "$ECR_REGISTRY/microservices/$($svc):latest"
    
    Write-Host "=== $svc pushed successfully ===" -ForegroundColor Green
}
```

---

## Step 6: Install AWS Load Balancer Controller (for Ingress)

```powershell
# Install Helm (if not installed)
# Download from: https://get.helm.sh/helm-v3.14.0-windows-amd64.zip

# Add EKS Helm chart repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Create IAM service account for ALB controller
eksctl create iamserviceaccount `
    --cluster=microservices-eks `
    --namespace=kube-system `
    --name=aws-load-balancer-controller `
    --role-name AmazonEKSLoadBalancerControllerRole `
    --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess `
    --approve `
    --region ap-south-1

# Install ALB Ingress Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller `
    -n kube-system `
    --set clusterName=microservices-eks `
    --set serviceAccount.create=false `
    --set serviceAccount.name=aws-load-balancer-controller `
    --set region=ap-south-1 `
    --set vpcId=$(terraform -chdir=deploy/terraform output -raw vpc_id)
```

---

## Step 7: Deploy Microservices to EKS

```powershell
cd D:\WSMicroservice\microservice-project

# Replace REPLACE_IN_CI in microservices.yaml with actual ECR base URL
$ECR_BASE = "392186013048.dkr.ecr.ap-south-1.amazonaws.com/microservices"
(Get-Content deploy/eks/microservices.yaml) -replace 'REPLACE_IN_CI', $ECR_BASE | Set-Content deploy/eks/microservices.yaml

# Apply Kubernetes manifests
kubectl apply -f deploy/eks/platform-config.yaml
kubectl apply -f deploy/eks/microservices.yaml

# Watch deployment progress
kubectl -n microservices get pods -w
```

Wait until all pods show `Running` and `Ready` (1/1 or 2/2).

---

## Step 8: Verify Deployment

```powershell
# Check all pods
kubectl -n microservices get pods

# Check all services
kubectl -n microservices get svc

# Check ingress (for API Gateway external URL)
kubectl -n microservices get ingress

# Check logs of any pod
kubectl -n microservices logs -f deployment/config-server
kubectl -n microservices logs -f deployment/eureka-server
kubectl -n microservices logs -f deployment/api-gateway

# Port-forward to test locally
kubectl -n microservices port-forward svc/api-gateway 8080:80
# Then visit: http://localhost:8080/actuator/health
```

---

## Step 9: Set Up Jenkins CI/CD Pipeline

### 9.1 Launch Jenkins on EC2

```powershell
# Create a Jenkins EC2 instance (t3.medium, Amazon Linux 2)
# In AWS Console: EC2 → Launch Instance
# - Name: jenkins-server
# - AMI: Amazon Linux 2
# - Type: t3.medium
# - Storage: 30 GB
# - Security Group: Allow ports 22 (SSH), 8080 (Jenkins), 50000 (Jenkins Agent)
# - Key pair: Select/create your key pair
```

### 9.2 Install Jenkins on EC2

SSH into the EC2 instance:
```bash
# Install Java 17
sudo yum install -y java-17-amazon-corretto-devel

# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins

# Start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker jenkins

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Maven
sudo yum install -y maven

# Restart Jenkins to pick up Docker group
sudo systemctl restart jenkins
```

### 9.3 Configure Jenkins

1. Open `http://<jenkins-ec2-public-ip>:8080`
2. Get initial password: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
3. Install suggested plugins + these additional plugins:
   - **Amazon Web Services SDK**
   - **Pipeline: AWS Steps**
   - **Docker Pipeline**
   - **Kubernetes CLI**
   - **SonarQube Scanner**
   - **Slack Notification**
   - **AnsiColor**

### 9.4 Add Jenkins Credentials

Go to **Manage Jenkins → Credentials → System → Global credentials**:

| ID | Kind | Description |
|---|---|---|
| `aws-jenkins-creds` | AWS Credentials | Your AWS Access Key & Secret Key |
| `sonar-token` | Secret text | SonarQube token (optional) |
| `slack-webhook` | Secret text | Slack webhook URL (optional) |

### 9.5 Create Pipeline Job

1. **New Item** → Name: `microservices-pipeline` → **Pipeline**
2. Under **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: Your Git repo URL
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
3. **Save**

### 9.6 Configure EKS Access for Jenkins

On the Jenkins EC2:
```bash
# Configure AWS CLI for Jenkins user
sudo su - jenkins
aws configure
# Enter: Access Key, Secret Key, Region: ap-south-1, Output: json

# Configure kubectl
aws eks update-kubeconfig --region ap-south-1 --name microservices-eks
kubectl get nodes  # should work
```

### 9.7 Run the Pipeline

Click **Build with Parameters**:
- DEPLOY_ENV: `dev` (for first test), then `prod` for production
- RUN_TESTS: ✅
- RUN_SONAR: ❌ (skip unless SonarQube is set up)
- IMAGE_TAG: leave empty (uses build number)

---

## 🔧 Troubleshooting

### Terraform State Lock Issues
```powershell
cd D:\WSMicroservice\microservice-project\deploy\terraform
terraform force-unlock -force <LOCK_ID>

# Or manually clear DynamoDB
aws dynamodb delete-item `
    --table-name terraform-state-lock `
    --key '{"LockID":{"S":"microservices-tfstate-123456789012/prod/terraform.tfstate"}}' `
    --region ap-south-1
```

### IAM Permission Errors
Use the updated IAM policy in `deploy/iam-policy-terraform.json` — it includes:
- `iam:CreatePolicy` / `iam:DeletePolicy` (for EKS cluster encryption policy)
- `iam:CreateServiceLinkedRole` (for ElastiCache, RDS)

### Pod CrashLoopBackOff
```powershell
kubectl -n microservices describe pod <pod-name>
kubectl -n microservices logs <pod-name> --previous
```

### RDS Connection Issues from Pods
Ensure the EKS security group can reach the RDS security group on port 3306.
```powershell
# Check security groups
aws ec2 describe-security-groups --group-ids sg-0cd166441207d53b6 --region ap-south-1
```

---

## 📊 Resource Summary

| Resource | Type | Cost Estimate (ap-south-1) |
|---|---|---|
| EKS Cluster | 1× cluster | ~$72/month |
| EKS Nodes | 3× t3.medium | ~$90/month |
| RDS MySQL | 3× db.t3.micro (Multi-AZ) | ~$45/month |
| ElastiCache Redis | 2× cache.t3.micro | ~$24/month |
| MSK Kafka | 3× kafka.t3.small | ~$150/month |
| NAT Gateways | 3× (one per AZ) | ~$99/month |
| **Total estimated** | | **~$480/month** |

> 💡 **Cost Tip:** For dev/staging, you can reduce costs by:
> - Using `single_nat_gateway = true` (~$66 savings)
> - Using single-AZ RDS (`multi_az = false`)
> - Using 1 MSK broker instead of 3

---

## ✅ Quick Command Reference

```powershell
# === TERRAFORM ===
cd D:\WSMicroservice\microservice-project\deploy\terraform
terraform apply -auto-approve          # Create all infrastructure
terraform output                       # Show all output values
terraform destroy -auto-approve        # DESTROY everything (careful!)

# === KUBECTL ===
kubectl -n microservices get pods      # List pods
kubectl -n microservices get svc       # List services
kubectl -n microservices get ingress   # List ingress
kubectl -n microservices logs -f deploy/<name>   # Stream logs
kubectl -n microservices rollout restart deploy/<name>  # Restart

# === ECR ===
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 392186013048.dkr.ecr.ap-south-1.amazonaws.com
docker push 392186013048.dkr.ecr.ap-south-1.amazonaws.com/microservices/<service>:<tag>

# === EKS ===
aws eks update-kubeconfig --region ap-south-1 --name microservices-eks
```

