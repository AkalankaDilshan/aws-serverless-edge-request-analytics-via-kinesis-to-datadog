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

## ACM variables
variable "raw_domain_name" {
  type        = string
  description = "actuall raw domain name for cerficate" # like zerocloud.click
  default     = "cloudretail.store"
}

variable "hosted_zone_id" {
  type        = string
  description = "route 53 Hosted zone ID"
  default     = "Z06745293W4YDJCDPOLW2"
}

## Route53
variable "domain_name" {
  type        = string
  description = "actual domain name"
  default     = "test.cloudretail.store"
}

## Kinesis firehose 

#https://aws-kinesis-http-intake.logs.datadoghq.com/v1/input
#https://aws-kinesis-http-intake.logs.us3.datadoghq.com/api/v2/logs?dd-protocol=aws-kinesis-firehose
#https://aws-kinesis-http-intake.logs.us5.datadoghq.com/api/v2/logs?dd-protocol=aws-kinesis-firehose
#https://aws-kinesis-http-intake.logs.ap1.datadoghq.com/api/v2/logs?dd-protocol=aws-kinesis-firehose
#https://aws-kinesis-http-intake.logs.ap2.datadoghq.com/api/v2/logs?dd-protocol=aws-kinesis-firehose
#https://aws-kinesis-http-intake.logs.datadoghq.eu/v1/input
#https://aws-kinesis-http-intake.logs.ddog-gov.com/v1/input
variable "datadog_url" {
  description = "correct region dd url"
  type        = string
  default     = "https://aws-kinesis-http-intake.logs.us5.datadoghq.com/api/v2/logs?dd-protocol=aws-kinesis-firehose"
}

variable "datadog_api_key" {
  description = "Datadog API key used to authenticate the Firehose HTTP endpoint."
  type        = string
  sensitive   = true
  #default     = "dsfxcdvdfv" ## for destroy
}

## Tags variables
variable "environment" {
  description = "project behavior"
  type        = string
  default     = "Production"
}