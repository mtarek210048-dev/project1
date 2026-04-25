# 3-Tier AWS Web Application

A production-ready 3-tier web application deployed on AWS using **Terraform** as Infrastructure as Code.

## Architecture

```
                        ┌─────────────────────────────────────────────────────┐
                        │                      AWS Cloud                       │
                        │                                                       │
  Users ──────────────► │  CloudFront (CDN + HTTPS)                            │
                        │       │                 │                             │
                        │       ▼                 ▼                             │
                        │   S3 Bucket         ALB (Public Subnets)             │
                        │  (Static Assets)        │                             │
                        │                         ▼                             │
                        │              ┌─── Private Subnets ───┐               │
                        │              │  EC2 Auto Scaling Group │              │
                        │              │  (Node.js Express App)  │              │
                        │              └──────────┬──────────────┘              │
                        │                         │                             │
                        │                         ▼                             │
                        │              ┌─── Private Subnets ───┐               │
                        │              │    RDS MySQL 8.0       │               │
                        │              └───────────────────────┘               │
                        └─────────────────────────────────────────────────────┘
```

## Services Used

| Layer       | Service                          | Purpose                              |
|-------------|----------------------------------|--------------------------------------|
| Networking  | VPC, Subnets, IGW, NAT Gateway   | Isolated network with public/private tiers |
| CDN         | CloudFront                       | HTTPS termination, caching, routing  |
| Compute     | EC2 + ALB + Auto Scaling Group   | Scalable app servers in private tier |
| Database    | RDS MySQL 8.0                    | Relational DB in private subnet      |
| Storage     | S3                               | Static assets, encrypted at rest     |
| IaC         | Terraform                        | All infrastructure as code           |
| Security    | Security Groups, IAM Roles, OAC  | Least-privilege access throughout    |

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.5.0 installed
- An AWS account with sufficient permissions

## Deployment

### 1. Clone the repo

```bash
git clone https://github.com/<your-username>/3-tier-aws-app.git
cd 3-tier-aws-app/terraform
```

### 2. Set up variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

Set the DB password as an environment variable (never put it in a file):

```bash
export TF_VAR_db_password="YourStrongPassword123!"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

Terraform will output the CloudFront URL when done:

```
cloudfront_url = "https://d1234abcd.cloudfront.net"
```

### 4. Destroy (to avoid AWS charges)

```bash
terraform destroy
```

## Project Structure

```
3-tier-aws-app/
├── terraform/
│   ├── main.tf                  # Root — wires all modules together
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # CloudFront URL, ALB DNS, etc.
│   ├── terraform.tfvars.example # Example config (copy → terraform.tfvars)
│   └── modules/
│       ├── vpc/                 # VPC, subnets, IGW, NAT, route tables
│       ├── compute/             # ALB, ASG, EC2 Launch Template, IAM
│       ├── database/            # RDS MySQL, DB subnet group, SG
│       ├── storage/             # S3 bucket, encryption, OAC policy
│       └── cdn/                 # CloudFront distribution, OAC
└── .gitignore
```

## API Endpoints

| Method | Path         | Description              |
|--------|--------------|--------------------------|
| GET    | `/health`    | ALB health check         |
| GET    | `/`          | App info (region, bucket)|
| GET    | `/items`     | List all items from RDS  |
| POST   | `/items`     | Create item `{ "name": "..." }` |
| DELETE | `/items/:id` | Delete item by ID        |
| GET    | `/files`     | List objects in S3       |

## Security Highlights

- EC2 instances are in **private subnets** — not directly accessible from the internet
- RDS is in **private subnets** — accessible only from the app EC2 security group
- S3 is **fully private** — CloudFront accesses it via OAC (Origin Access Control)
- IAM role on EC2 has **least-privilege** S3 access only
- DB password is passed via environment variable, never stored in code

## Cost Estimate (eu-north-1, dev config)

| Resource              | Approx. Monthly Cost |
|-----------------------|----------------------|
| 2x EC2 t3.micro       | ~$15                 |
| RDS db.t3.micro       | ~$15                 |
| NAT Gateway           | ~$35                 |
| ALB                   | ~$16                 |
| S3 + CloudFront       | ~$1–2                |
| **Total**             | **~$82/month**       |

> 💡 Destroy the stack when not in use to avoid charges: `terraform destroy`

## Author

**Moe** — AWS Certified Cloud Practitioner | SAA-C03 Candidate  
[LinkedIn](https://linkedin.com/in/your-profile) · [GitHub](https://github.com/your-username)
