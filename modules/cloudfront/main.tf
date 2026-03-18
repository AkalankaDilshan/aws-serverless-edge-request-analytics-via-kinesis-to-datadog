data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

## necessary header pass to origin
resource "aws_cloudfront_origin_request_policy" "geo_device" {
  name    = "enable-cf-geo-and-device-headers"
  comment = "Passes CloudFront geo/device headers and all viewer headers to origin"

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "CloudFront-Viewer-Country",
        "CloudFront-Viewer-Country-Name",
        "CloudFront-Viewer-Country-Region",
        "CloudFront-Viewer-Country-Region-Name",
        "CloudFront-Viewer-City",
        "CloudFront-Viewer-Latitude",
        "CloudFront-Viewer-Longitude",
        "CloudFront-Viewer-Time-Zone",
        "CloudFront-Viewer-Postal-Code",
        "CloudFront-Viewer-Metro-Code",
        "CloudFront-Is-Desktop-Viewer",
        "CloudFront-Is-Mobile-Viewer",
        "CloudFront-Is-Tablet-Viewer",
        "CloudFront-Is-SmartTV-Viewer",
        "CloudFront-Forwarded-Proto",
      ]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }

  cookies_config {
    cookie_behavior = "all"
  }
}

# disable all other headers its AWs managed policy
locals {
  # AWS managed policy: CachingDisabled
  caching_disabled_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}


resource "aws_cloudfront_distribution" "cdn_distribution" {

  origin {
    domain_name = var.instance_dns_domain_name
    origin_id   = var.instance_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # or "http-only" or "https-only" or "match-viewer"
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

    # Use managed CachingDisabled — required when forwarding all headers/cookies
    # Cannot mix cache_policy_id with forwarded_values block
    cache_policy_id          = local.caching_disabled_policy_id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.geo_device.id

    # Lambda@Edge: viewer-request 
    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = var.lambdaedge_function_arn # must be versioned ARN
      include_body = false                       # set true only if need POST body
    }
  }

  # Price class (select based on audience)
  price_class = "PriceClass_100" # Use only North America and Europe edges | PriceClass_All | PriceClass_200

  # cdn logs
  logging_config {
    bucket          = var.logs_bucket_domain_name
    prefix          = "cloudfront/" # Optional: organizes logs into a subfolder
    include_cookies = false         # Set true to log cookie details (useful for debugging)
  }

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

  tags = var.tags
}

resource "aws_security_group_rule" "allow_http" {
  type        = "ingress"
  description = "Allow HTTP traffic from cloudfront"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  #prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  security_group_id = var.instance_sg_id
  depends_on        = [aws_cloudfront_distribution.cdn_distribution]
}

resource "aws_security_group_rule" "allow_https" {
  type        = "ingress"
  description = "Allow HTTPS traffic from cloudfront"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  #prefix_list_ids = [ data.aws_ec2_managed_prefix_list.cloudfront.id ]
  security_group_id = var.instance_sg_id
  depends_on        = [aws_cloudfront_distribution.cdn_distribution]
}