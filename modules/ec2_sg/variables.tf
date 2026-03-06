variable "sg_name" {
  description = "ec2 security group name"
  type        = string
}

variable "vpc_id" {
  description = "main vpc id"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}