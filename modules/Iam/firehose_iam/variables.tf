variable "delivery_stream_name" {
  description = "Name for the Kinesis Firehose delivery stream and its IAM role"
  type        = string
}

variable "kinesis_stream_arn" {
  description = "ARN of the Kinesis Data Stream"
  type        = string
}

variable "data_lake_s3_bucket_arn" {
  description = "bucket arn"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}