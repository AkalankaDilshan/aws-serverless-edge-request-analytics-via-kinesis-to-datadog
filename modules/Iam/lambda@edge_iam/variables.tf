variable "role_name" {
  description = "lambda function role"
  type        = string
}

variable "kinesis_region" {
  description = "region of kinesis"
  type        = string
}

variable "kinesis_stream_name" {
  description = "stream name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}