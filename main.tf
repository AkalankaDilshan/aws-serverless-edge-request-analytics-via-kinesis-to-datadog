provider "aws" {
  region = var.region
}

module "main_vpc" {
  source = "./modules/vpc"

  vpc_name            = "production-vpc"
  cidr_block          = "193.168.0.0/16"
  availability_zone   = var.availability_zones
  public_subnet_cidr  = ["193.168.1.0/24"]
  private_subnet_cidr = ["193.168.3.0/24"]
  tags = {
    Environment = var.environment
    Name        = "production-vpc"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}

# ec2 security group
module "ec2_sg" {
  source  = "./modules/ec2_sg"
  sg_name = "server-sg"
  vpc_id  = module.main_vpc.vpc_id
  tags = {
    Environment = var.environment
    Name        = "production-ec2-sg"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}

# ec2 server
module "ec2_server" {
  source = "./modules/ec2"

  instance_name = "production-server"
  instance_type = var.instance_type

  ami_id             = var.ec2_ami_id
  subnet_id          = module.main_vpc.public_subnet_ids[0]
  security_group_id  = module.ec2_sg.ec2_sg_id
  is_allow_public_ip = true
  key_pair_name      = var.ec2_key_pair_name

  ebs_volume_size = "30"
  ebs_volume_type = "gp3"

  tags = {
    Environment = var.environment
    Name        = "production-server"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}

# module "elastic_ip" {
#   source      = "./modules/eip"
#   instance_id = module.ec2_server.instance_id
#   tags = {
#     Environment = var.environment
#     Name        = "production-server-ip"
#     CreatedBy   = "AkalankaDilshan"
#     ManagedBy   = "Terraform"
#   }
# }

# Kinesis Data Stream
module "kinesis_stream" {
  source                 = "./modules/kinesis_data_stream"
  stream_name            = "cloudfront-edge-events"
  retention_period_hours = 24
  tags = {
    Environment = var.environment
    Name        = "cloudfront-edge-event-stream"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}

# Lambda Iam role
module "iam_lambdaedge" {
  source    = "./modules/Iam/lambda@edge_iam"
  role_name = "lambdaedge-function-iam-role"
  kinesis_region = var.region
  kinesis_stream_name = module.kinesis_stream.stream_name
  tags = {
    Environment = var.environment
    Name        = "lambda-iam-role"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}

## Lambda@Edge
module "lambdaedge_function" {
  source              = "./modules/lambda@edge"
  function_name       = "cloudfront-edge-metadata"
  function_iam_role   = module.iam_lambdaedge.lambda_role_arn
  kinesis_stream_name = module.kinesis_stream.stream_name
  kinesis_stream_arn  = module.kinesis_stream.stream_arn
  kinesis_region      = var.region
  depends_on          = [module.iam_lambdaedge, module.kinesis_stream]
  tags = {
    Environment = var.environment
    Name        = "cloudfront-edge-metadata-collector-function"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}

## ACM
module "aws_acm_certificate" {
  source         = "./modules/acm"
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
  tags = {
    Environment = var.environment
    Name        = "acm-certificate"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}

## Cloudfront log s3 bucket
module "cdn_logs_bucket" {
  source      = "./modules/s3/cloudfront_log_s3"
  domain_name = var.domain_name
  tags = {
    Environment = var.environment
    Name        = "cdn-log-bucket"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}

## Data-Lake S3 bucket
module "datalake_bucket" {
  source             = "./modules/s3/data_lake_s3"
  bucket_name_prefix = "edge-analytics-logs"
  tags = {
    Environment = var.environment
    Name        = "edge-analytics-logs-datalake-bucket"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}

## Cloudfront
module "cloudfront" {
  source                   = "./modules/cloudfront"
  domain_name              = var.domain_name
  instance_dns_domain_name = module.ec2_server.instance_public_dns
  instance_id              = module.ec2_server.instance_id
  lambdaedge_function_arn  = module.lambdaedge_function.lambda_qualified_arn
  logs_bucket_domain_name  = module.cdn_logs_bucket.cdn_logs_bucket_domain_name
  acm_certificate_arn      = module.aws_acm_certificate.acm_certificate_arn
  depends_on               = [module.ec2_server, module.aws_acm_certificate, module.iam_lambdaedge, module.cdn_logs_bucket]
  tags = {
    Environment = var.environment
    Name        = "aws-cloudfront"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}

## Route53
module "route53" {
  source                            = "./modules/route_53"
  domain_name                       = var.domain_name
  hosted_zone_id                    = var.hosted_zone_id
  cloudfront_distribution_name      = module.cloudfront.cdn_domain_name
  cloudfront_distribution_hosted_id = module.cloudfront.cloudfront_distribution_hosted_zone_id
  depends_on                        = [module.cloudfront]
  tags = {
    Environment = var.environment
    Name        = "test.cloudretail.store"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}


## Iam role for firehose
module "iam_firehose" {
  source                  = "./modules/Iam/firehose_iam"
  delivery_stream_name    = "cloudfront-edge-firehose" # for create names
  kinesis_stream_arn      = module.kinesis_stream.stream_arn
  data_lake_s3_bucket_arn = module.datalake_bucket.s3_bucket_arn
  depends_on              = [module.datalake_bucket, module.kinesis_stream]
  tags = {
    Environment = var.environment
    Name        = "firehose-iam-role"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}

## Kinesis firehole
module "kinesis_firehose" {
  source                = "./modules/kinesis_firehose"
  kinesis_stream_arn    = module.kinesis_stream.stream_arn
  delivery_stream_name  = "cloudfront-edge-events" # for firehose name
  datadog_url           = var.datadog_url
  datadog_api_key       = var.datadog_api_key
  firehose_iam_role_arn = module.iam_firehose.firehose_role_arn
  s3_backup_arn         = module.datalake_bucket.s3_bucket_arn
  depends_on            = [module.kinesis_stream, module.datalake_bucket, module.iam_firehose]
  tags = {
    Environment = var.environment
    Name        = "firehose-iam-role"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
    Module      = "kinesis_firehose"
    Source      = module.kinesis_stream.stream_name
    Destination = "datadog+s3"
  }
}