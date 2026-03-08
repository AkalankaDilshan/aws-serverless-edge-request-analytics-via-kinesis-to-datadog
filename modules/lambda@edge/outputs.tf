output "lambda_qualified_arn" {
  description = <<-EOT
    Versioned Lambda ARN — pass this as var.lambdaedge_function_arn to the
    CloudFront module.  Lambda@Edge requires a versioned ARN; $LATEST is rejected.
    Example value: arn:aws:lambda:us-east-1:123456789012:function:cloudfront-edge-metadata:3
  EOT
  value       = aws_lambda_function.edge_metadata.qualified_arn
}

output "lambda_function_arn" {
  description = "Unversioned Lambda function ARN (without :version suffix)."
  value       = aws_lambda_function.edge_metadata.arn
}