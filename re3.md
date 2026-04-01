# ⚡ AWS Edge Request Analytics Pipeline
> Real-time request analytics at the CloudFront edge — zero latency impact, streamed to Datadog, archived to S3 Glacier.

![AWS](https://img.shields.io/badge/AWS-CloudFront%20%7C%20Lambda%40Edge%20%7C%20Kinesis%20%7C%20EC2-FF9900?style=flat&logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-Cloud-7B42BC?style=flat&logo=terraform&logoColor=white)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?style=flat&logo=githubactions&logoColor=green)
![Datadog](https://img.shields.io/badge/Monitoring-Datadog-632CA6?style=flat&logo=datadog&logoColor=white)
![IaC](https://img.shields.io/badge/IaC-100%25%20Terraform-7B42BC?style=flat&logo=terraform)

📖 **[View Full Documentation →](./DETAILED_README.md)**

<img width="922" height="582" alt="Screenshot 2026-03-31 at 13 32 38" src="https://github.com/user-attachments/assets/6ff958e2-51d9-42de-92a4-c766f692176b" />

---

## ✨ What It Does

| | |
|---|---|
| 🌍 **Global Edge Capture** | Lambda@Edge runs at every CloudFront PoP worldwide, capturing geo, device, referrer & more |
| ⚡ **Zero Latency** | Kinesis `PutRecord` is fire-and-forget — the viewer is never blocked |
| 📊 **Real-time Dashboards** | Firehose streams directly to Datadog Logs API in under 60 seconds |
| 🏊 **S3 Data Lake** | Raw logs auto-tiered: Standard → IA → Glacier → Deep Archive (96% cost saving) |
| 🔒 **Secure by Design** | KMS encryption, least-privilege IAM, no public S3 buckets |
| 🚀 **Fully Automated** | Terraform Cloud + GitHub Actions — PR triggers plan, merge triggers apply |

---

## 🛠️ Stack

`AWS CloudFront` · `Lambda@Edge` · `Kinesis Data Streams` · `Kinesis Firehose` · `EC2` · `VPC` · `S3` · `Route 53` · `ACM` · `Datadog` · `Terraform Cloud` · `GitHub Actions`

---

## ⚙️ CI/CD Flow

```
Pull Request  →  fmt + validate + plan  →  plan posted as PR comment
Merge to main →  terraform apply        →  live in AWS
```

State managed by **Terraform Cloud** · Secrets stored as **GitHub Actions Secrets** · Never touches local machine

---

## 📁 Key Modules

```
modules/
 ├── vpc/                 ← VPC, subnets, IGW
 ├── ec2/                 ← Nginx origin server
 ├── cloudfront/          ← CDN + Lambda@Edge trigger
 ├── lambda@edge/         ← Metadata capture function (Node.js 18)
 ├── kinesis_data_stream/ ← ON_DEMAND stream, KMS encrypted
 ├── kinesis_firehose/    ← Datadog HTTP + S3 backup destination
 └── s3/data_lake_s3/     ← Glacier lifecycle policy
```

---

## 📊 Results — Live Datadog Output

Once deployed, edge metadata flows into Datadog in real time. Below are live log captures from the running pipeline:

> **Datadog Log Explorer** — each record contains geo, device, URI, referrer, status code and more, arriving within seconds of the viewer request.

<!-- 
  HOW TO ADD YOUR SCREENSHOTS:
  1. Go to your GitHub repo → Issues → New Issue
  2. Drag and drop your Datadog screenshots into the comment box
  3. GitHub generates a URL like: https://github.com/user-attachments/assets/xxx
  4. Copy those URLs and replace the src values below
  5. Close the issue without saving
-->

| Datadog Live Logs | Log Record Detail |
|---|---|
| ![Datadog Logs](./docs/screenshots/datadog-logs.png) | ![Datadog Record](./docs/screenshots/datadog-record.png) |

---

## 🚨 Important — Cost Warning

> [!CAUTION]
> **Several services in this project are NOT covered by the AWS Free Tier.**
> They will generate real charges immediately upon deployment — even with zero traffic.

| Service | Billing Starts | Why |
|---|---|---|
| ☁️ **CloudFront** | Immediately | Data transfer & request charges, no free tier for custom distributions |
| 📡 **Kinesis Data Streams** | Immediately | ON_DEMAND charges per GB ingested + shard hour |
| 🚒 **Kinesis Firehose** | Immediately | Charges per GB delivered to destination |
| 🖥️ **EC2 t3.micro** | After 12 months | Free tier only covers `t2.micro` in first year |
| 🌐 **NAT Gateway** | Immediately | Hourly + per GB processed |

**I left this stack running for a few days during development and got this:**

<!-- Replace src below with your actual AWS bill screenshot uploaded via GitHub Issues -->
<div align="center">
  <img src="./docs/screenshots/aws-bill.png" alt="$60 AWS Bill" width="680"/>
  <br/>
  <sub>💸 Real AWS bill from leaving this stack idle during testing — yes, really $60</sub>
</div>

<br/>

**Protect yourself before deploying:**

- ✅ Set an **[AWS Budget alert](https://console.aws.amazon.com/billing/home#/budgets)** at $5 — takes 2 minutes
- ✅ Run **`terraform destroy`** the moment you finish testing
- ✅ Enable **AWS Cost Anomaly Detection** to catch spikes early
- ✅ **Disassociate Kinesis shards** when not actively testing

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE).

---

## 🤝 Contributions

Contributions are welcome! Please submit a pull request or raise an issue for suggestions.

---

## 🔗 Connect with Me

For any queries, feel free to reach out via LinkedIn or open an issue in the repository.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/akalanka007)