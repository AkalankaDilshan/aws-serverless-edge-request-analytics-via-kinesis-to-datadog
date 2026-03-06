data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "server_sg" {
  name = var.sg_name
  description = "allow HTTP,HTTPS for alb sg and SSH for my ip"
  vpc_id = var.vpc_id
  tags = {
    Name = var.sg_name
  }
}

resource "aws_security_group_rule" "allow_ssh" {
  type = "ingress"
  description = "SSH ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["220.247.240.217/32"]
  security_group_id = aws_security_group.server_sg.id
}

resource "aws_security_group_rule" "allow_http" {
  type = "ingress"
  description = "Allow HTTP traffic from cloudfront"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  security_group_id = aws_security_group.server_sg.id
}

resource "aws_security_group_rule" "allow_https" {
  type = "ingress"
  description = "Allow HTTPS traffic from cloudfront"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  prefix_list_ids = [ data.aws_ec2_managed_prefix_list.cloudfront.id ]
  security_group_id = aws_security_group.server_sg.id
}

# outbound rules
resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.server_sg.id
}



