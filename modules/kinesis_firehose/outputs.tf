output "firehose_arn" {
  description = "firehose arn"
  value = aws_kinesis_firehose_delivery_stream.this.arn
}

output "firehose_name" {
  description = "Name of the Kinesis Firehose delivery stream."
  value       = aws_kinesis_firehose_delivery_stream.this.name
}

output "firehose_role_arn" {
  description = "IAM execution role ARN used by Firehose"
  value       = aws_iam_role.firehose.arn
}