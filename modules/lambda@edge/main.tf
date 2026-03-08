# Lambda@Edge has no environment variable support, so we want to pass values via templatefile()
locals {
  rendered_function = templatefile("${path.module}/function/index.js.tpl", {
    kinesis_stream_name = var.kinesis_stream_name
    kinesis_region      = var.kinesis_region
  })

  function_version_label = var.function_name
}

# write the rendered JS so archive_file can zip it
resource "local_file" "lambda_source" {
  content         = local.rendered_function
  filename        = "${path.module}/function/index.js"
  file_permission = "0644"
}

# zip the rendered JS, archive_file can zip it
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_source.filename
  output_path = "${path.module}/function/lambda_edge_${var.function_name}.zip"
  depends_on  = [local_file.lambda_source]
}

data "aws_caller_identity" "current" {}

# Lambda function
resource "aws_lambda_function" "edge_metadata" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  function_name = var.function_name
  role          = var.function_iam_role
  runtime       = "nodejs18.x"

  # REQUIRED: publish=true creates a numbered version; CloudFront rejects $LATEST
  publish = true

  # hard limits for viewr-request event type
  memory_size = 128 # max 128 MB for viewer-request 
  timeout     = 5   # max 5 s  for viewer-request

  description = "CloudFront edge metadata collector → Kinesis stream: ${var.kinesis_stream_name}"

  tags = merge(var.tags, {
    LambdaEdge    = "true"
    EventType     = "viewer-request"
    KinesisStream = var.kinesis_stream_name
  })

  depends_on = [
    data.archive_file.lambda_zip
  ]
}