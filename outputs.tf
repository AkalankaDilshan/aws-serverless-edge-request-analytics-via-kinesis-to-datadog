output "ec2_public_dns" {
  value = module.ec2_server.instance_public_dns
}

output "cloudfront_domain_name" {
  value = module.cloudfront.cdn_domain_name
}

output "kinesis_stream_arn" {
  value = module.kinesis_stream.stream_arn
}

output "lambda_edge_arn" {
  value = module.lambdaedge_function.lambda_qualified_arn
}