data "aws_ami" "specific_ami" {
  filter {
    name   = "ami-id"
    values = [var.ami_id]
  }
}

resource "aws_instance" "server_instance" {
  ami                     = data.aws_ami.specific_ami.id
  instance_type           = var.instance_type
  subnet_id               = var.subnet_id
  vpc_security_group_ids  = [var.security_group_id]
  disable_api_termination = true  # protects the instance from accidental deletion
  ebs_optimized           = false # Dedicated network connection between the EC2 & EBS,Lower latency,Consistent performance for I/O-intensive

  ### Basic Syntax of Terraform Conditional ###
  #condition ? true_value : false_value

  # Conditional IAM instance profile
  iam_instance_profile = var.iam_instance_profile_name != null ? var.iam_instance_profile_name : null

  root_block_device {
    volume_type = var.ebs_volume_type
    volume_size = var.ebs_volume_size
    encrypted   = true
  }

  key_name = var.key_pair_name

  tags = {
    Name = var.instance_name
  }
}