output "ec2_public_dns" {
  value = module.ec2_server.instance_public_dns
}