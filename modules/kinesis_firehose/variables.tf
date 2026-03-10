variable "delivery_stream_name" {
  description = "name for kinesis firehore"
  type        = string
  #default     = "cloudfront-edge-firehose"
}

variable "kinesis_stream_arn" {
  description = "kinesis stram arn"
  type        = string
}

variable "firehose_iam_role_arn" {
  description = "iam role arn"
  type = string
}

variable "s3_backup_arn" {
  description = "data lake bucket arn"
  type = string
}

#https://aws-kinesis-http-intake.logs.datadoghq.com/v1/input
#https://aws-kinesis-http-intake.logs.us3.datadoghq.com/api/v2/logs?dd-protocol=aws-kinesis-firehose
#https://aws-kinesis-http-intake.logs.us5.datadoghq.com/api/v2/logs?dd-protocol=aws-kinesis-firehose
#https://aws-kinesis-http-intake.logs.ap1.datadoghq.com/api/v2/logs?dd-protocol=aws-kinesis-firehose
#https://aws-kinesis-http-intake.logs.ap2.datadoghq.com/api/v2/logs?dd-protocol=aws-kinesis-firehose
#https://aws-kinesis-http-intake.logs.datadoghq.eu/v1/input
#https://aws-kinesis-http-intake.logs.ddog-gov.com/v1/input
variable "datadog_url" {
  description = "correct region dd url"
  type = string
}

variable "datadog_api_key" {
  description = "Datadog API key used to authenticate the Firehose HTTP endpoint."
  type      = string
  sensitive = true

  validation {
    condition     = length(var.datadog_api_key) > 0
    error_message = "datadog_api_key must not be empty."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}