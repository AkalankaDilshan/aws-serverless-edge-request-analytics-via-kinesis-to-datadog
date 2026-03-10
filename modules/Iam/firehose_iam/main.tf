data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "firehose" {
  name = "${var.delivery_stream_name}-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FirehoseAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# read from kinesis data stream
resource "aws_iam_role_policy" "firehose_kinesis_read" {
  name   = "${var.delivery_stream_name}-kinesis-read"
  role   = aws_iam_role.firehose.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "KinesisRead"
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListShards",
        ]
        Resource = var.kinesis_stream_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_s3_write" {
  name = "${var.delivery_stream_name}-s3-write"
  role = aws_iam_role.firehose.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Write"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
        ]
        Resource = [
          "${var.data_lake_s3_bucket_arn}",
          "${var.data_lake_s3_bucket_arn}/*",
        ]
      }
    ]
  })
}