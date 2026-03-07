resource "aws_acm_certificate" "certificate" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  # Without lifecycle(defult)
  #. destroy old certificate
  #.  create new certificate

  # With lifecycle
  #. create new certificate
  #. switch service to new certificate
  #. destroy old certificate
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  zone_id         = var.hosted_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 300
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn = aws_acm_certificate.certificate.arn

  ## Terraform list comprehension (similar to python)
  ## [for ITEM in COLLECTION : VALUE]
  # fqdn = fully qualified domain name
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}

