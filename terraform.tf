terraform {
  cloud {

    organization = "RootLab"

    workspaces {
      name = "aws-serverless-edge-request-analytics-via-kinesis-to-datadog"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.5.0"
}