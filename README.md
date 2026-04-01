# 🌍 AWS Edge Request Analytics Pipeline
> Capture rich request metadata at the CloudFront edge — geo, device, referrer, and more —
> stream it asynchronously through Kinesis to Datadog for real-time dashboards,
> and archive it to an S3 Data Lake with automatic Glacier tiering.
> All infrastructure is managed by Terraform Cloud and deployed via GitHub Actions CI/CD.

![Terraform](https://img.shields.io/badge/Terraform-Cloud-7B42BC?style=flat&logo=terraform&logoColor=white)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?style=flat&logo=githubactions&logoColor=green)
![Datadog](https://img.shields.io/badge/Monitoring-Datadog-632CA6?style=flat&logo=datadog&logoColor=black)

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

<table border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="60%">
<img src="https://github.com/user-attachments/assets/732faedf-d9e4-4856-b14b-af3e0dc8de71"/>
</td>
<td width="40%">
<img src="https://github.com/user-attachments/assets/dbc17abb-dd0e-4414-99f0-030c8cf759a4"/>
</td>
</tr>
</table>



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
  <img width="1117" height="682" alt="Screenshot 2026-04-01 at 09 34 54" src="https://github.com/user-attachments/assets/844cae8f-b6f3-4a0a-afc7-1e1530104c0d" />
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
