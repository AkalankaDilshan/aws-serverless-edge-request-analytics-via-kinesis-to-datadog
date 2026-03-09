output "s3_bucket_name" {
  description = "Name of the S3 Data Lake bucket storing raw edge logs."
  value = aws_s3_bucket.log_lake.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 Data Lake bucket — useful for attaching additional bucket policies."
  value       = aws_s3_bucket.log_lake.arn
}