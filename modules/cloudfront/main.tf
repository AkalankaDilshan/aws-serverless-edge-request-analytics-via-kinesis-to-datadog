resource "aws_cloudfront_distribution" "cdn_distribution" {

  origin {
    domain_name = var.instance_dns_domain_name
    origin_id = var.instance_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer" # or "http-only" or "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # general settings
  aliases = concat(
    [var.domain_name, "www.${var.domain_name}"],
    var.alternate_domain_names != null ? var.alternate_domain_names : []
  )
  enabled         = true
  is_ipv6_enabled = true

  # cache behavior 
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.instance_id # must match origin_id above 
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Lambda@Edge: viewer-request 
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = var.lambdaedge_function_arn # must be versioned ARN
      include_body = false                        # set true only if need POST body
    }

    # forwarding and caching
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    # Forward all headers/cookies for ALB to process properly
    forwarded_values {
      query_string = true
      headers      = ["*"] # Forward all headers for ec2 to process(disable cloudfront caching)

      cookies {
        forward = "all" # Forward all cookies to ALB
      }
    }
  }

  # Price class (select based on audience)
  price_class = "PriceClass_100" # Use only North America and Europe edges | PriceClass_All | PriceClass_200

  # goe restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none" # No geographic restrictions
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}