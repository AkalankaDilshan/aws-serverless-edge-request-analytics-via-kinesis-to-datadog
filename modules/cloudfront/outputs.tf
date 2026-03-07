output "cdn_domain_name" {
  value       = aws_cloudfront_distribution.cdn_distribution.domain_name
  description = "The CloudFront distribution URL"
}

output "hosted_zone_id" {
  value = aws_cloudfront_distribution.cdn_distribution.hosted_zone_id
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.cdn_distribution.id
  description = "the ID of the cloudFront distribution"
}