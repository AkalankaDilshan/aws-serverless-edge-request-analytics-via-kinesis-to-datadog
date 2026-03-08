variable "stream_name" {
  type        = string
  description = "kinesis data stream name" # "cloudfront-edge-events"
}

variable "retention_period_hours" {
  type        = number
  description = "records are kept in the stream before expiring"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}