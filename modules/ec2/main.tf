data "aws_ami" "specific_ami" {
  owners = ["self", "amazon"]

  filter {
    name   = "image-id" # Use "image-id" instead of "ami-id"
    values = [var.ami_id]
  }
}

resource "aws_instance" "server_instance" {
  ami                         = data.aws_ami.specific_ami.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = var.is_allow_public_ip
  disable_api_termination     = false # protects the instance from accidental deletion, false for dev, true for prod
  ebs_optimized               = true  # Dedicated network connection between the EC2 & EBS,Lower latency,Consistent performance for I/O-intensive
  monitoring                  = true  # Enables detailed monitoring

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

  # Enforces Instance Metadata Service Version 2 (IMDSv2) to mitigate SSRF-based credential theft attacks.
  # IMDSv1 allows any process on the instance to query metadata via a simple HTTP GET request without authentication.
  # IMDSv2 requires a session-oriented token, which must be obtained via a PUT request before accessing metadata.
  # Reference: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html
  metadata_options {
    http_endpoint               = "enabled"  # Enables the Instance Metadata Service (IMDS) endpoint on the instance
    http_tokens                 = "required" # Enforces IMDSv2 by requiring a session token; disables IMDSv1 completely
    http_put_response_hop_limit = 1          # Restricts metadata access to the instance itself; prevents containerized workloads from reaching the host metadata service
  }

  tags = {
    Name = var.instance_name
  }
}