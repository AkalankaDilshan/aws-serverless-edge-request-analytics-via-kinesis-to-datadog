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

  #ami_id            = var.ec2_ami_id
  ami_id = "ami-09807aafaf7a91e8f"
  subnet_id         = module.main_vpc.public_subnet_ids[0]
  security_group_id = module.ec2_sg.ec2_sg_id
  key_pair_name     = var.ec2_key_pair_name

  ebs_volume_size = "30"
  ebs_volume_type = "gp3"

  tags = {
    Environment = var.environment
    Name        = "production-server"
    CreatedBy   = "AkalankaDilshan"
    ManagedBy   = "Terraform"
  }
}