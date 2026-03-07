resource "aws_eip" "eip" {
  instance = var.instance_id
  domain   = "vpc"
}