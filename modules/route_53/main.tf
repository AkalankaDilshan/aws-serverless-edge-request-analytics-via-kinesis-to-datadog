resource "aws_route53_record" "cloudfront_alias" {
  zone_id = var.hosted_zone_id
  name = var.domain_name
  type = "A"
  alias {
    name = var.cloudfront_distribution_name
    zone_id = var.cloudfront_distribution_hosted_id
    evaluate_target_health = false 
  }
}