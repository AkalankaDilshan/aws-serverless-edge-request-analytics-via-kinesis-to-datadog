data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "log_lake" {
  bucket = "${var.bucket_name_prefix}-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.force_destroy_bucket

  tags = merge(var.tags, {
    Module  = "kinesis_firehose"
    Purpose = "edge-analytics-data-lake"
  })
}

# block all public access
resource "aws_s3_bucket_public_access_block" "log_lake" {
  bucket = aws_s3_bucket.log_lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# encrypt
resource "aws_s3_bucket_server_side_encryption_configuration" "log_lake" {
  bucket = aws_s3_bucket.log_lake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# data lake lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "log_lake" {
  bucket = aws_s3_bucket.log_lake.id

  rule {
    id     = "edge-logs-tiering"
    status = "Enabled"

    filter {
      prefix = "edge-logs/"
    }

    # 30 days → Standard-IA (warm)
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # 90 days → Glacier Instant Retrieval (cold) 
    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    # 180 days → Glacier Deep Archive (frozen)
    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }
  }
}


