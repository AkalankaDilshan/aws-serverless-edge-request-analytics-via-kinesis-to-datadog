output "aws_route53_record" {
  value = aws_route53_record.cloudfront_alias.records
}