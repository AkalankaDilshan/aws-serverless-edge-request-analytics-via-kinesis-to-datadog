# ⚡ AWS Edge Request Analytics Pipeline

> Real-time request analytics at the CloudFront edge — zero latency impact, streamed to Datadog, archived to S3 Glacier.

![AWS](https://img.shields.io/badge/AWS-CloudFront%20%7C%20Lambda%40Edge%20%7C%20Kinesis%20%7C%20EC2-FF9900?style=flat&logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-Cloud-7B42BC?style=flat&logo=terraform&logoColor=white)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?style=flat&logo=githubactions&logoColor=green)
![Datadog](https://img.shields.io/badge/Monitoring-Datadog-632CA6?style=flat&logo=datadog&logoColor=white)
![IaC](https://img.shields.io/badge/IaC-100%25%20Terraform-7B42BC?style=flat&logo=terraform)

<img width="922" height="582" alt="Screenshot 2026-03-31 at 13 32 38" src="https://github.com/user-attachments/assets/6ff958e2-51d9-42de-92a4-c766f692176b" />


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
## License
This project is licensed under the [MIT License](./LICENSE).

## Contributions
Contributions are welcome! Please submit a pull request or raise an issue for suggestions.

## Connect with Me
For any queries, feel free to reach out via LinkedIn or open an issue in the repository.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](www.linkedin.com/in/akalanka007)
---

📖 **[View Full Documentation →](./README-DETAILED.md)**

---

<div align="center">
  Built by <a href="https://github.com/AkalankaDilshan">AkalankaDilshan</a> &nbsp;·&nbsp; ⭐ Star if useful!
</div>
