# User Management Placeholder Backend – DevOps Assignment

This repository implements a production-style deployment of a simple placeholder backend service on AWS, using:

- Python (Flask) as the backend
- Docker for containerization
- AWS ECS Fargate for compute
- Application Load Balancer (ALB) for ingress
- RDS PostgreSQL for persistence
- ECR as the container registry
- CloudWatch Logs and ECS Container Insights for observability
- Terraform (modular) for infrastructure-as-code
- GitHub Actions for CI/CD

The goal is to demonstrate real-world DevOps practices with clean infrastructure, automated delivery, and a clear separation of concerns.

---

## Architecture Overview

High-level architecture:

```
GitHub (main branch)
        |
        |  (push)
        v
+-------------------------+
|     GitHub Actions      |
|  - Build Docker image   |
|  - Push to ECR          |
|  - Terraform apply      |
+------------+------------+
             |
             | AWS API (ECR, ECS, RDS, ALB, VPC)
             v
      +-----------------------------+
      |           AWS VPC           |
      |                             |
      |  +-----------------------+  |
      |  |        ALB            |  |
      |  |  HTTP -> /, /health   |  |
      |  +----------+------------+  |
      |             |               |
      |             v               |
      |    +-------------------+    |
      |    |   ECS Fargate     |    |
      |    | Python/Flask App  |    |
      |    +---------+---------+    |
      |              | DB_CONN      |
      |              v              |
      |    +-------------------+    |
      |    |   RDS PostgreSQL   |   |
      |    +-------------------+    |
      +-----------------------------+
```

---

## Repository Structure

```
.
├── backend/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── infra/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── network/
│       ├── security/
│       ├── ecr/
│       ├── database/
│       └── ecs_service/
│
└── .github/
    └── workflows/
        └── deploy.yml
```

---

## Backend Service (Python + Flask)

The backend is intentionally simple and acts as a placeholder for a user management service. It exposes:

- `GET /` – returns a JSON status document.
- `GET /health` – used by the ALB for health checks.

Local usage:

```
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python server.py
```

Docker usage:

```
docker build -t user-mgmt-local backend/
docker run -p 3000:3000 user-mgmt-local
```

---

## Infrastructure (Terraform, Modular)

All infrastructure is defined using Terraform with a modular structure:

- VPC with public subnets
- Security groups (ALB, ECS, database)
- ECR repository
- ECS cluster, task definition, and service
- ALB with listeners and target group
- CloudWatch log groups
- RDS PostgreSQL instance

Deploy manually:

```
export TF_VAR_db_password="StrongPass123!"
cd infra
terraform init
terraform apply
```

Outputs include:

- `alb_dns_name`
- `db_endpoint`
- `ecr_repository_url`

---

## CI/CD – GitHub Actions

The workflow performs:

1. Configure AWS credentials
2. Terraform init + apply (infra + ECR)
3. Build backend image
4. Push image to ECR
5. Update ECS task definition
6. Redeploy service
7. Output ALB DNS name

Required secrets:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `TF_VAR_db_password`

---

## Deployment Guide

This section provides detailed instructions for deploying the application to AWS, with explanations of each step.

### Prerequisites

Before deploying, ensure you have:

1. **AWS Account** with appropriate permissions:
   - EC2 (for VPC, Security Groups)
   - ECS (for Fargate clusters and services)
   - ECR (for container registry)
   - RDS (for PostgreSQL database)
   - IAM (for roles and policies)
   - CloudWatch (for logging)

2. **AWS CLI** installed and configured:
   ```bash
   aws --version
   aws configure
   ```

3. **Terraform** installed (version 1.7.5 or compatible):
   ```bash
   terraform version
   ```

4. **Docker** installed (for local testing and manual builds):
   ```bash
   docker --version
   ```

5. **GitHub Repository** with Actions enabled (for automated deployment)

### Deployment Methods

There are two ways to deploy this application:

1. **Automated Deployment via GitHub Actions** (Recommended)
2. **Manual Deployment using Terraform and AWS CLI**

---

### Method 1: Automated Deployment (GitHub Actions)

This is the recommended approach as it automates the entire deployment pipeline.

#### Step 1: Configure GitHub Secrets

Navigate to your GitHub repository → Settings → Secrets and variables → Actions, and add the following secrets:

- **`AWS_ACCESS_KEY_ID`**: Your AWS access key ID
  - *Explanation*: Used to authenticate with AWS services during the CI/CD pipeline
  
- **`AWS_SECRET_ACCESS_KEY`**: Your AWS secret access key
  - *Explanation*: The secret key paired with your access key ID for authentication
  
- **`AWS_REGION`**: AWS region (e.g., `eu-central-1`, `us-east-1`)
  - *Explanation*: The AWS region where all resources will be deployed
  
- **`TF_VAR_db_password`**: Strong password for the RDS PostgreSQL database
  - *Explanation*: The master password for the database instance. Use a strong password (minimum 8 characters, mix of letters, numbers, and special characters)

#### Step 2: Trigger Deployment

The deployment can be triggered in two ways:

**Option A: Automatic (on push to main branch)**
- Simply push your code to the `main` branch:
  ```bash
  git add .
  git commit -m "Deploy application"
  git push origin main
  ```

**Option B: Manual (via GitHub Actions UI)**
- Go to your repository → Actions tab
- Select the "ci-cd-backend" workflow
- Click "Run workflow" → Select branch → Run workflow

#### Step 3: Monitor Deployment

1. **Watch the GitHub Actions workflow**:
   - Go to Actions tab in your repository
   - Click on the running workflow to see real-time logs
   - The workflow will show progress for each step

2. **What happens during deployment**:
   - **Terraform Init**: Initializes Terraform and downloads required providers
   - **Terraform Apply (Infra + ECR)**: Creates all AWS infrastructure including:
     - VPC with public and private subnets
     - Security groups for ALB, ECS, and RDS
     - ECR repository for storing Docker images
     - RDS PostgreSQL database instance
     - ECS cluster, task definition, and service
     - Application Load Balancer (ALB)
   - **ECR Login**: Authenticates Docker with AWS ECR
   - **Build Docker Image**: Builds the backend container image
   - **Push to ECR**: Uploads the image to the ECR repository
   - **Terraform Apply (Update ECS)**: Updates the ECS task definition with the new image and redeploys the service

3. **Get the Application URL**:
   - At the end of the workflow, you'll see the ALB DNS name in the output
   - The format will be: `user-mgmt-dev-alb-xxxxx.region.elb.amazonaws.com`
   - Access your application at: `http://<alb-dns-name>/`

#### Step 4: Verify Deployment

1. **Check Application Health**:
   ```bash
   curl http://<alb-dns-name>/
   curl http://<alb-dns-name>/health
   ```

2. **Check ECS Service Status**:
   - Go to AWS Console → ECS → Clusters → `user-mgmt-dev-cluster`
   - Verify the service is running and tasks are healthy

3. **Check CloudWatch Logs**:
   - Go to AWS Console → CloudWatch → Log groups → `/ecs/user-mgmt-dev-backend`
   - Verify application logs are being generated

---

### Method 2: Manual Deployment

Use this method if you prefer to deploy manually or need more control over the process.

#### Step 1: Set Environment Variables

```bash
export AWS_REGION="eu-central-1"  # Change to your preferred region
export TF_VAR_db_password="YourStrongPassword123!"  # Use a strong password
```

**Explanation**: These environment variables configure:
- `AWS_REGION`: Determines which AWS region Terraform will deploy to
- `TF_VAR_db_password`: Sets the database password (required by Terraform as a sensitive variable)

#### Step 2: Initialize Terraform

```bash
cd infra
terraform init
```

**Explanation**: 
- Downloads the required Terraform providers (AWS, etc.)
- Initializes the backend (if configured)
- Prepares the working directory for Terraform operations

#### Step 3: Review Deployment Plan

```bash
terraform plan
```

**Explanation**:
- Shows what resources Terraform will create, modify, or destroy
- Review the plan carefully to ensure it matches your expectations
- This is a dry-run and doesn't make any changes

#### Step 4: Deploy Infrastructure (First Time)

```bash
terraform apply
```

**Explanation**:
- Creates all AWS resources defined in the Terraform configuration:
  - **VPC Module**: Virtual Private Cloud with subnets across availability zones
  - **Security Module**: Security groups that control network traffic:
    - ALB security group: Allows HTTP/HTTPS from internet
    - ECS security group: Allows traffic from ALB only
    - Database security group: Allows PostgreSQL (5432) from ECS only
  - **ECR Module**: Container registry for storing Docker images
  - **Database Module**: RDS PostgreSQL instance in private subnets
  - **ECS Module**: ECS cluster, task definition, service, and ALB

**Note**: The first deployment will create the infrastructure but the ECS service may fail initially because no container image exists in ECR yet.

#### Step 5: Build and Push Docker Image

After infrastructure is created, you need to build and push the application image:

```bash
# Get the ECR repository URL from Terraform output
ECR_URL=$(terraform output -raw ecr_repository_url)

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_URL

# Build the Docker image
cd ../backend
docker build -t backend:latest .

# Tag the image for ECR
docker tag backend:latest ${ECR_URL}:latest

# Push to ECR
docker push ${ECR_URL}:latest
```

**Explanation**:
- **ECR Login**: Authenticates Docker with AWS ECR using your AWS credentials
- **Build**: Creates a Docker image from the Dockerfile in the backend directory
- **Tag**: Tags the image with the ECR repository URL and `latest` tag
- **Push**: Uploads the image to ECR so ECS can pull it

#### Step 6: Update ECS with New Image

```bash
cd ../infra
terraform apply -var="container_image=${ECR_URL}:latest"
```

**Explanation**:
- Updates the ECS task definition with the new container image URI
- ECS automatically starts a new deployment with the updated image
- The service will perform a rolling update (if configured) to replace old tasks with new ones

#### Step 7: Get Application URL

```bash
terraform output alb_dns_name
```

**Explanation**: 
- Outputs the DNS name of the Application Load Balancer
- This is the public endpoint where your application is accessible
- Access your application at: `http://<alb-dns-name>/`

#### Step 8: Verify Deployment

```bash
# Test the root endpoint
curl http://$(terraform output -raw alb_dns_name)/

# Test the health endpoint
curl http://$(terraform output -raw alb_dns_name)/health
```

**Expected Response**:
```json
{
  "status": "ok",
  "service": "user-management-placeholder",
  "env": "dev",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

---

### Updating the Application

#### Automated Updates (GitHub Actions)

Simply push changes to the `main` branch. The CI/CD pipeline will:
1. Build a new Docker image
2. Push it to ECR
3. Update the ECS service with the new image
4. ECS will perform a rolling deployment

#### Manual Updates

1. Make changes to your code
2. Rebuild and push the Docker image (Step 5 from manual deployment)
3. Update ECS (Step 6 from manual deployment)

---

### Troubleshooting

#### Application Not Accessible

1. **Check ALB Target Group Health**:
   - AWS Console → EC2 → Target Groups → Select your target group
   - Verify targets are healthy (should show "healthy" status)
   - If unhealthy, check the health check path (`/health`) is responding

2. **Check Security Groups**:
   - Verify ALB security group allows inbound traffic on port 80/443
   - Verify ECS security group allows traffic from ALB security group

3. **Check ECS Service**:
   - AWS Console → ECS → Clusters → Services
   - Verify tasks are running (not stopped or failed)
   - Check task logs in CloudWatch for errors

#### Database Connection Issues

1. **Verify Database Endpoint**:
   ```bash
   terraform output db_endpoint
   ```

2. **Check Security Groups**:
   - Database security group should allow port 5432 from ECS security group
   - Verify ECS tasks can reach the database subnet

3. **Check Database Status**:
   - AWS Console → RDS → Databases
   - Verify database is "Available" (not "Creating" or "Failed")

#### Terraform Errors

1. **Authentication Issues**:
   ```bash
   aws sts get-caller-identity
   ```
   Verify your AWS credentials are configured correctly.

2. **Region Mismatch**:
   Ensure the `AWS_REGION` environment variable matches your Terraform configuration.

3. **Resource Limits**:
   Some AWS accounts have default limits (e.g., VPCs, EIPs). Check AWS Service Quotas if you hit limits.

#### ECS Tasks Failing to Start

1. **Check Task Definition**:
   - Verify the container image URI is correct
   - Check CPU and memory allocations are valid

2. **Check CloudWatch Logs**:
   - AWS Console → CloudWatch → Log groups → `/ecs/user-mgmt-dev-backend`
   - Review logs for startup errors

3. **Check IAM Roles**:
   - Verify ECS task execution role has permissions to pull from ECR
   - Verify task execution role has CloudWatch Logs permissions

---

### Cleanup (Destroying Resources)

To remove all deployed resources:

**Using Terraform**:
```bash
cd infra
terraform destroy
```

**Warning**: This will delete all resources including:
- RDS database (data will be lost unless backups are configured)
- ECS service and tasks
- ALB and target groups
- ECR repository (images will be deleted)
- VPC and networking resources

**Note**: If `db_skip_final_snapshot` is `true` (default), the database will be deleted without a final snapshot. Set it to `false` in `vars.tfvars` if you want to preserve data.

---

## Possible Improvements

- Private subnets for ECS tasks
- NAT Gateway instead of public IP assignment
- Secrets Manager for DB credentials
- ALB access logs to S3
- Autoscaling policies for ECS
- Multi-environment CI/CD
- Terraform remote backend (S3 + DynamoDB)

---

## Summary

This project demonstrates:

- Clean Terraform module design
- Automated CI/CD pipeline
- Containerized backend deployed on ECS Fargate
- Load-balanced, observable AWS architecture
- End-to-end DevOps delivery workflow