locals {
  function_dir    = "{path.module}/function"
  rendered_source = "${local.function_dir}/index.js"
  zip_output_path = "${path.module}/builds/lambda_edge.zip"
}

# Render index.js.tpl -> index.js 
resource "local_file" "lambda_source" {
  content = templatefile("${local.function_dir}/index.js.tpl", {
    kinesis_stream_name = var.kinesis_stream_name
    kinesis_region      = var.kinesis_region
  })
  filename = local.rendered_source
}

# run npm install inside the function directory adter index.js rendered
resource "null_resource" "npm_install" {
  triggers = {
    package_json = filemd5("${local.function_dir}/package.json")
    source_hash  = local_file.lambda_source.content_md5
  }

  provisioner "local-exec" {
    command     = "npm install --prefix ${local.function_dir} --omit=dev --no-fund --no-audit"
    working_dir = path.module
  }

  depends_on = [local_file.lambda_source]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = local.function_dir
  output_path = local.zip_output_path
  excludes    = ["*.tpl"]

  depends_on = [null_resource.npm_install]
}

resource "aws_lambda_function" "edge_metadata" {
  function_name    = var.function_name
  role             = var.function_iam_role
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  publish          = true

  timeout     = 5
  memory_size = 128

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