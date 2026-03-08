resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "cdn_logs" {
  bucket = "${var.domain_name}-cdn-logs-${random_string.bucket_suffix.result}"
}

resource "aws_s3_bucket_ownership_controls" "cdn_logs_control" {
  bucket = aws_s3_bucket.cdn_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cdn_logs_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.cdn_logs]
  bucket     = aws_s3_bucket.cdn_logs.id
  acl        = "log-delivery-write" # Grants CloudFront permission to write logs
}