# ALB Origin Variables
variable "instance_dns_domain_name" {
  description = "ec2 dns name"
  type        = string
}

variable "instance_id" {
  description = "instance id"
  type        = string
}

variable "lambdaedge_function_arn" {
  description = "lamda@edge funcion arn" # aws_cloudfront_function.example.arn
  type        = string
}

variable "logs_bucket_domain_name" {
  description = "cdn log bucket domain name"
  type = string
}

variable "origin_secret_header" {
  description = "Optional secret header for origin verification"
  type        = string
  default     = null
}


# Domain Names
variable "domain_name" {
  description = "Primary domain name" # like abc.com
  type        = string
}

variable "alternate_domain_names" {
  description = "Alternate domain names" # like www.abc.lk
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  type        = string
  description = "acm value"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}