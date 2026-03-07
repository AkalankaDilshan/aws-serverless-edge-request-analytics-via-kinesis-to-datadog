variable "domain_name" {
  type        = string
  description = "domain name for Route 53 and CloudFront integration"
}

variable "hosted_zone_id" {
  type        = string
  description = "Route 53 hosted zone id for the domain"
}

variable "cloudfront_distribution_hosted_id" {
  type        = string
  description = "the cloudfront distribition ID to map the domain"
}

variable "cloudfront_distribution_name" {
  type        = string
  description = "the cloudfront distribition name to map the domain"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}