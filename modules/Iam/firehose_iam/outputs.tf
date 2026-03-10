output "firehose_role_arn" {
  description = "IAM execution role ARN used by Firehose — useful if you need to attach additional policies."
  value       = aws_iam_role.firehose.arn
}