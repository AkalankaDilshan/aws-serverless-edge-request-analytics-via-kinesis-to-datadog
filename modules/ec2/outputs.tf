output "instance_id" {
  value = aws_instance.server_instance.id
}

output "instance_private_ip" {
  value = aws_instance.server_instance.private_ip
}

output "instance_public_dns" {
  value = aws_instance.server_instance.public_dns
}