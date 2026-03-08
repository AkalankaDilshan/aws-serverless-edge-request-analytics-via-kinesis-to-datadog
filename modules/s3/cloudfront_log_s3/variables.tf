variable "domain_name" {
  type        = string
  description = "main domian name"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}