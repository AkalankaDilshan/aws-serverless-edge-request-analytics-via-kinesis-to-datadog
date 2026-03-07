variable "domain_name" {
  type        = string
  description = "domain name for Route 53 and CloudFront integration"
}

variable "hosted_zone_id" {
  type        = string
  description = "Route 53 hosted zone id for the domain"
}

variable "is_allow_public_ip" {
  description = "is it allow public ip or not"
  type        = bool
  default     = true
}