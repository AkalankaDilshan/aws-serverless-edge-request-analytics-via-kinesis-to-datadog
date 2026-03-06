terraform {
  cloud {

    organization = "RootLab"

    workspaces {
      name = "aws-serverless-edge-request-analytics-via-kinesis-to-datadog"
    }
  }
}