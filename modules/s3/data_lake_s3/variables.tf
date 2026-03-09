variable "bucket_name_prefix" {
  description = "Prefix for the S3 Data Lake bucket name"
  type    = string
  #default = "edge-analytics-logs"
}

variable "force_destroy_bucket" {
  description = "When true, allows Terraform to destroy the S3 bucket even if it contains objects."
  type    = bool
  default = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}