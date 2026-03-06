variable "region" {
  type    = string
  default = "us-east-1"
}

## VPC Variables
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a"]
}

## EC2 Variables
variable "instance_type" {
  type        = string
  description = "ec2 instance type"
  default     = "t3.small"
}

variable "ec2_key_pair_name" {
  type        = string
  description = "prod ec2 key pair name"
  default     = "ravindus_account_ec2_key"
}

variable "ec2_ami_id" {
  type        = string
  description = "ravindu's-account-test-ec2-ami"
  default     = "ami-09807aafaf7a91e8f"
}

## Tags variables
variable "environment" {
  description = "project behavior"
  type        = string
  default     = "Production"
}