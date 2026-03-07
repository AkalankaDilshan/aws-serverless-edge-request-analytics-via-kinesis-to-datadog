variable "instance_id" {
  type        = string
  description = "ec2 instance id"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}