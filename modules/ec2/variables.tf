variable "instance_name" {
  type        = string
  description = "Name for the EC2 instance "
}

variable "ami_id" {
 type = string
 description = "AMI ID"
}

variable "instance_type" {
  type        = string
  description = "type for the EC2 instance"
}

variable "subnet_id" {
  type        = string
  description = "subnet id for EC2 instace"
}

variable "security_group_id" {
  type        = string
  description = "security group id"
}
variable "ebs_volume_type" {
  type        = string
  description = "type of instance value"
  #default     = "gp3"
}

variable "ebs_volume_size" {
  type        = number
  description = "size of instance value"
  #default     = 30
}

variable "key_pair_name" {
  type        = string
  description = "name for ec2 instance key-pair"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
  default     = null
}