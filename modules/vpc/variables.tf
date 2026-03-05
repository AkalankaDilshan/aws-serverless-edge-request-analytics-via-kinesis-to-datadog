variable "vpc_name" {
  description = "name for vpc"
  type        = string
}

variable "cidr_block" {
  description = "CIDR address for vpc"
  type = string
}

variable "public_subnet_cidr" {
  type = list(string)
  description = "List of CIDR blocks for the public subnet"
}

variable "private_subnet_cidr" {
  type = list(string)
  description = "List of CIDR block for the private subnet"
}

variable "availability_zone" {
  type = list(string)
  description = "List of the availability zones"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}