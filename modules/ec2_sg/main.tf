resource "aws_security_group" "server_sg" {
  name = var.sg_name
  description = "allow HTTP,HTTPS for alb sg and SSH for my ip"
  vpc_id = var.vpc_id
  tags = {
    Name = var.sg_name
  }
}

resource "aws_security_group_rule" "allow_" {
  
}



