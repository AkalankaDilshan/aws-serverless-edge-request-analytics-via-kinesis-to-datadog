# 🌐 AWS Serverless Edge Request Analytics via Kinesis to Datadog

> Capture rich request metadata at the CloudFront edge — geo, device, referrer, and more —
> stream it asynchronously through Kinesis to Datadog for real-time dashboards,
> and archive it to an S3 Data Lake with automatic Glacier tiering.
> All infrastructure is managed by Terraform Cloud and deployed via GitHub Actions CI/CD.

---
<img width="922" height="582" alt="Screenshot 2026-03-31 at 13 32 38" src="https://github.com/user-attachments/assets/7c657388-422d-4d5b-9070-a5eaf90c653b" />

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Data Flow](#-data-flow)
- [Metadata Captured](#-metadata-captured)
- [S3 Data Lake & Glacier Lifecycle](#-s3-data-lake--glacier-lifecycle)
- [Prerequisites](#-prerequisites)
- [Setup Guide](#-setup-guide)
  - [1. Terraform Cloud Setup](#1-terraform-cloud-setup)
  - [2. GitHub Actions Setup](#2-github-actions-setup)
  - [3. Datadog Setup](#3-datadog-setup)
  - [4. Variables Configuration](#4-variables-configuration)
- [CI/CD Workflow](#-cicd-workflow)
- [Terraform Modules](#-terraform-modules)
- [Outputs](#-outputs)
- [Cost Estimate](#-cost-estimate)
- [Contributing](#-contributing)

---

## 🔍 Overview

This project deploys a **fully serverless edge analytics pipeline** on AWS. Every HTTP request that passes through CloudFront triggers a Lambda@Edge function that captures rich metadata and publishes it — without adding any latency to the viewer experience.

**Key capabilities:**

- ⚡ **Zero latency impact** — Kinesis publish is fire-and-forget; the viewer request is never blocked
- 🌍 **Global edge capture** — Lambda@Edge runs in every CloudFront edge location worldwide
- 📊 **Real-time dashboards** — Kinesis Firehose streams directly to Datadog Logs API
- 🏊 **Data Lake archival** — All raw logs land in S3, auto-tiered to Glacier Deep Archive
- 🔒 **Secure by design** — KMS encryption at rest, least-privilege IAM, no public S3 buckets
- 🚀 **Fully automated** — Terraform Cloud + GitHub Actions handle all infrastructure changes

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **IaC** | Terraform (HCL) |
| **State Management** | Terraform Cloud |
| **CI/CD** | GitHub Actions |
| **CDN / Edge** | AWS CloudFront |
| **Edge Compute** | AWS Lambda@Edge (Node.js 18.x) |
| **Stream Ingestion** | AWS Kinesis Data Streams (ON_DEMAND) |
| **Stream Delivery** | AWS Kinesis Data Firehose |
| **Real-time Analytics** | Datadog Logs + Dashboards |
| **Data Lake** | Amazon S3 (Standard → IA → Glacier → Deep Archive) |
| **Origin Server** | AWS EC2 (Nginx) inside a VPC |
| **DNS** | AWS Route 53 |
| **TLS Certificates** | AWS ACM |
| **Encryption** | AWS KMS (managed keys) |

---

## 📁 Project Structure

```
aws-serverless-edge-request-analytics-via-kinesis-to-datadog/
│
├── .github/
│   └── workflows/
│       └── terraform.yml          # GitHub Actions CI/CD pipeline
│
├── modules/
│   ├── vpc/                       # VPC, public/private subnets, IGW, route tables
│   ├── ec2_sg/                    # Security group for EC2 origin server
│   ├── ec2/                       # EC2 instance (Nginx origin server)
│   ├── acm/                       # ACM TLS certificate + DNS validation
│   ├── route_53/                  # Route 53 A-record → CloudFront
│   ├── cloudfront/                # CloudFront distribution + Lambda@Edge association
│   ├── s3/
│   │   ├── cloudfront_log_s3/     # S3 bucket for CloudFront access logs
│   │   └── data_lake_s3/          # S3 Data Lake with Glacier lifecycle rules
│   ├── Iam/
│   │   ├── lambda@edge_iam/       # IAM role for Lambda@Edge (Kinesis PutRecord)
│   │   └── firehose_iam/          # IAM role for Firehose (Kinesis read + S3 write)
│   ├── lambda@edge/               # Lambda@Edge function + templatefile rendering
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── function/
│   │       └── index.js.tpl       # Lambda handler template (stream name baked in)
│   ├── kinesis_data_stream/       # Kinesis Data Stream (ON_DEMAND, KMS encrypted)
│   └── kinesis_firehose/          # Firehose → Datadog HTTP + S3 backup
│
├── main.tf                        # Root module — wires all modules together
├── variables.tf                   # Root input variables
├── outputs.tf                     # Root outputs (CloudFront URL, stream ARN, etc.)
├── terraform.tf                   # Terraform Cloud backend + provider version locks
└── .gitignore
```

---

## 🔄 Data Flow

```
1. User's browser makes a request to your domain
       ↓
2. Route 53 resolves the domain → CloudFront distribution
       ↓
3. CloudFront checks its cache
   ├── Cache HIT  → Returns cached response
   └── Cache MISS → Forwards request to EC2 origin (inside VPC)
       ↓
4. Lambda@Edge fires on the Viewer Request event
   └── Extracts metadata: geo headers, device type, IP, URI, referrer, UA
   └── PutRecord to Kinesis Data Stream (async, fire-and-forget — no latency added)
       ↓
5. Viewer gets the response immediately (Lambda@Edge does NOT block the request)
       ↓
6. Kinesis Data Stream buffers the metadata record
       ↓
7. Kinesis Firehose reads from the stream and delivers to:
   ├── Datadog Logs API  → Real-time dashboards (< 60 second latency)
   └── S3 Data Lake      → Raw GZIP logs partitioned by date/hour
       ↓
8. S3 Lifecycle Policy automatically tiers old logs:
   └── 0–30d Standard → 30–90d Standard-IA → 90–180d Glacier IR → 180d+ Deep Archive
```

---

## 📦 Metadata Captured

Every edge request produces a JSON record with the following fields:

| Category | Fields |
|---|---|
| **Timestamps** | `timestamp`, `requestId`, `distributionId`, `eventType` |
| **Request** | `method`, `uri`, `querystring`, `host`, `protocol` |
| **Client** | `clientIp`, `userAgent`, `referrer`, `acceptLanguages`, `acceptEncoding` |
| **Geo** | `country`, `countryName`, `region`, `regionName`, `city`, `latitude`, `longitude`, `timezone`, `postalCode` |
| **Device** | `type` (mobile/tablet/desktop), `os`, `browser`, `browserVersion` |
| **Cache** | `cacheControl`, `pragma` |

> Geo data is sourced directly from **CloudFront's built-in viewer headers** — no GeoIP library needed, zero additional latency.

---

## 🏊 S3 Data Lake & Glacier Lifecycle

All raw logs are stored in S3 with automatic cost-optimized tiering:

```
Day 0    →  S3 Standard          $0.023/GB  (hot  — active Athena queries)
Day 30   →  S3 Standard-IA       $0.0125/GB (warm — infrequent access)
Day 90   →  S3 Glacier Instant   $0.004/GB  (cold — rare access, instant retrieval)
Day 180  →  S3 Glacier Deep Archive $0.00099/GB (frozen — 12hr retrieval, cheapest)
Day 365  →  Deleted              (configurable)
```

Logs are partitioned by date and hour for efficient Athena queries:
```
s3://edge-analytics-logs-{account_id}/
  └── edge-logs/
      └── 2026/
          └── 03/
              └── 31/
                  └── 14/
                      └── firehose-1-2026-03-31-14-00-00.gz
```

---

## ✅ Prerequisites

Before you begin, make sure you have the following:

- [ ] **AWS Account** with admin-level IAM access
- [ ] **Terraform Cloud account** — [sign up free](https://app.terraform.io/)
- [ ] **GitHub account** with access to this repository
- [ ] **Datadog account** — [14-day free trial](https://www.datadoghq.com/)
- [ ] **A registered domain** in Route 53 (e.g. `yourdomain.com`)
- [ ] **EC2 Key Pair** created in `us-east-1`

---

## 🚀 Setup Guide

### 1. Terraform Cloud Setup

**Step 1 — Create an Organization**

Sign in to [app.terraform.io](https://app.terraform.io) and create a new organization if you don't have one.

**Step 2 — Create a Workspace**

1. Click **New Workspace** → select **API-driven workflow**
2. Name it: `aws-edge-analytics` (or any name you prefer)
3. Click **Create workspace**

**Step 3 — Add AWS Credentials as Workspace Variables**

In your workspace, go to **Variables** and add the following as **Environment Variables**:

| Variable | Value | Sensitive |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | No |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | **Yes** |

**Step 4 — Add Terraform Variables**

Add these as **Terraform Variables** in your workspace:

| Variable | Example Value | Sensitive | Description |
|---|---|---|---|
| `datadog_api_key` | `abc123...` | **Yes** | Datadog API key |
| `datadog_url` | `https://aws-kinesis-http-intake.logs.datadoghq.com/v1/input` | No | Datadog intake URL |
| `domain_name` | `test.yourdomain.com` | No | Your Route 53 domain |
| `hosted_zone_id` | `Z1234567890ABC` | No | Route 53 hosted zone ID |
| `ec2_key_pair_name` | `my-key-pair` | No | EC2 key pair name |
| `ec2_ami_id` | `ami-0c02fb55956c7d316` | No | Amazon Linux 2 AMI ID |
| `instance_type` | `t3.micro` | No | EC2 instance type |
| `region` | `us-east-1` | No | AWS region |
| `environment` | `production` | No | Environment tag |

> ⚠️ **Important:** Lambda@Edge requires resources to be deployed in `us-east-1`. Keep `region = "us-east-1"`.

**Step 5 — Create a Terraform Cloud Team Token**

1. Go to **Organization Settings** → **Teams**
2. Create a team named `github-actions`
3. Go to **API tokens** → **Team Tokens** → **Create a team token**
4. Save this token — you'll add it to GitHub in the next step

---

### 2. GitHub Actions Setup

**Step 1 — Add Terraform Cloud Token to GitHub Secrets**

In your GitHub repository, go to **Settings → Secrets and variables → Actions** and add:

| Secret Name | Value |
|---|---|
| `TF_API_TOKEN` | Your Terraform Cloud team token from Step 5 above |

**Step 2 — Update terraform.tf with Your Workspace**

Edit `terraform.tf` and replace with your Terraform Cloud organization and workspace names:

```hcl
terraform {
  cloud {
    organization = "YOUR_ORG_NAME"
    workspaces {
      name = "aws-edge-analytics"
    }
  }
}
```

**Step 3 — Push to trigger the workflow**

```bash
git add .
git commit -m "chore: configure terraform cloud workspace"
git push origin main
```

---

### 3. Datadog Setup

**Step 1 — Get your API Key**

1. Log in to [app.datadoghq.com](https://app.datadoghq.com)
2. Go to **Organization Settings → API Keys**
3. Click **New Key**, name it `kinesis-firehose`, copy the key

**Step 2 — Find your Datadog site URL**

| Your Datadog site | Firehose URL |
|---|---|
| `datadoghq.com` (US1) | `https://aws-kinesis-http-intake.logs.datadoghq.com/v1/input` |
| `datadoghq.eu` (EU1) | `https://aws-kinesis-http-intake.logs.datadoghq.eu/v1/input` |
| `us3.datadoghq.com` | `https://aws-kinesis-http-intake.logs.us3.datadoghq.com/v1/input` |

**Step 3 — Verify Logs Arrive**

After deployment, go to **Datadog → Logs → Search** and filter by:
```
source:aws-lambda-edge
```

**Step 4 — Build Your Dashboard**

Suggested widgets for your Datadog dashboard:

| Widget | Field | Visualization |
|---|---|---|
| Traffic by Country | `geo.country` | World Map |
| Device Breakdown | `device.type` | Pie Chart |
| Requests Over Time | `timestamp` | Time Series |
| Top URIs | `uri` | Top List |
| Browser Split | `device.browser` | Bar Chart |
| Top Referrers | `referrer` | Top List |
| Error Rate | `statusCode` ≥ 400 | Gauge |

---

### 4. Variables Configuration

All sensitive values are managed in **Terraform Cloud** as workspace variables — they never touch your local machine or git history.

For local reference only, here is the shape of variables (do **not** create a `terraform.tfvars` — use Terraform Cloud variables instead):

```hcl
# ── AWS ───────────────────────────────────────────────────────────────────────
region             = "us-east-1"
environment        = "production"
availability_zones = ["us-east-1a", "us-east-1b"]
instance_type      = "t3.micro"
ec2_ami_id         = "ami-0c02fb55956c7d316"
ec2_key_pair_name  = "your-key-pair"

# ── Domain ────────────────────────────────────────────────────────────────────
domain_name      = "test.yourdomain.com"
hosted_zone_id   = "Z1234567890ABC"

# ── Datadog (set as sensitive in Terraform Cloud) ─────────────────────────────
datadog_api_key  = "sensitive - set in Terraform Cloud"
datadog_url      = "https://aws-kinesis-http-intake.logs.datadoghq.com/v1/input"
```

---

## ⚙️ CI/CD Workflow

This project uses **GitHub Actions + Terraform Cloud** for a fully automated deploy pipeline.

```
┌─────────────────────────────────────────────────────────────┐
│                    GITHUB ACTIONS WORKFLOW                   │
│                                                             │
│  Pull Request opened / updated                              │
│         ↓                                                   │
│  ┌─────────────────────┐                                    │
│  │  terraform fmt       │  ← Checks code formatting         │
│  │  terraform validate  │  ← Validates HCL syntax           │
│  │  terraform plan      │  ← Runs plan in Terraform Cloud   │
│  │  Post plan to PR     │  ← Plan output added as PR comment│
│  └─────────────────────┘                                    │
│         ↓                                                   │
│  PR Approved & merged to main                               │
│         ↓                                                   │
│  ┌─────────────────────┐                                    │
│  │  terraform apply     │  ← Auto-applies in Terraform Cloud│
│  └─────────────────────┘                                    │
└─────────────────────────────────────────────────────────────┘
```

**Workflow triggers:**

| Event | Action |
|---|---|
| Push to any branch (non-main) | `terraform plan` only |
| Pull Request to `main` | `terraform fmt` + `validate` + `plan` (posted as PR comment) |
| Merge to `main` | `terraform apply` (auto-deploy) |

**GitHub Actions workflow file:** `.github/workflows/terraform.yml`

The workflow authenticates to Terraform Cloud using the `TF_API_TOKEN` secret. Terraform Cloud handles the actual `plan` and `apply` operations, storing state remotely and enforcing run policies.

> 📖 Reference: [HashiCorp — Automate Terraform with GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)

---

## 🧩 Terraform Modules

| Module | Path | Description |
|---|---|---|
| `vpc` | `modules/vpc` | VPC, public/private subnets, IGW, route tables |
| `ec2_sg` | `modules/ec2_sg` | Security group — HTTP/HTTPS/SSH for EC2 origin |
| `ec2` | `modules/ec2` | EC2 instance (Nginx), EBS gp3 30GB |
| `acm` | `modules/acm` | ACM certificate + Route 53 DNS validation |
| `route_53` | `modules/route_53` | Alias A-record → CloudFront distribution |
| `cloudfront` | `modules/cloudfront` | CloudFront + Lambda@Edge association + access logs |
| `cloudfront_log_s3` | `modules/s3/cloudfront_log_s3` | S3 bucket for CloudFront standard access logs |
| `data_lake_s3` | `modules/s3/data_lake_s3` | S3 Data Lake with full Glacier lifecycle policy |
| `lambda@edge_iam` | `modules/Iam/lambda@edge_iam` | IAM role — trusts lambda + edgelambda, PutRecord |
| `firehose_iam` | `modules/Iam/firehose_iam` | IAM role — Kinesis read + S3 write |
| `lambda@edge` | `modules/lambda@edge` | Lambda function — rendered from `index.js.tpl` |
| `kinesis_data_stream` | `modules/kinesis_data_stream` | Kinesis stream — ON_DEMAND, KMS, 24h retention |
| `kinesis_firehose` | `modules/kinesis_firehose` | Firehose — Kinesis source, Datadog + S3 destination |

---

## 📤 Outputs

After a successful `terraform apply`, the following outputs are available in Terraform Cloud:

| Output | Description |
|---|---|
| `cloudfront_url` | CloudFront distribution domain (e.g. `xxxx.cloudfront.net`) |
| `custom_domain` | Your custom domain pointing to CloudFront |
| `kinesis_stream_arn` | ARN of the Kinesis Data Stream |
| `kinesis_stream_name` | Name of the Kinesis Data Stream |
| `firehose_arn` | ARN of the Kinesis Firehose delivery stream |
| `s3_datalake_bucket` | Name of the S3 Data Lake bucket |
| `lambda_function_arn` | ARN of the Lambda@Edge function |
| `lambda_qualified_arn` | Versioned ARN used by CloudFront |

---

## 💰 Cost Estimate

Estimated monthly cost for low-to-medium traffic (< 1M requests/month):

| Service | Estimated Cost |
|---|---|
| EC2 t3.micro | ~$8.50/month (free tier: $0) |
| CloudFront | ~$0.01 per 10K requests |
| Lambda@Edge | ~$0 (1M free requests/month) |
| Kinesis Data Stream (ON_DEMAND) | ~$0.04/GB ingested |
| Kinesis Firehose | ~$0.029/GB delivered |
| S3 Standard (first 30 days) | ~$0.023/GB |
| S3 Glacier Deep Archive (180d+) | ~$0.00099/GB |
| ACM | Free |
| Route 53 (hosted zone) | $0.50/month |
| **Total (low traffic estimate)** | **~$10–15/month** |

> 💡 Glacier Deep Archive is **23x cheaper** than S3 Standard — old logs cost almost nothing.

---

## 🤝 Contributing

Contributions, issues, and suggestions are welcome!

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request → GitHub Actions will automatically run `terraform plan` and post the output as a PR comment

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">

Built with ❤️ by [AkalankaDilshan](https://github.com/AkalankaDilshan)

⭐ If you found this useful, please star the repository!

</div>
