data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_kinesis_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["kinesis:PutRecord", "kinesis:PutRecords", ]
    #resources = ["arn:aws:kinesis:*:${data.aws_caller_identity.current.account_id}:stream/*"]
    resources = ["arn:aws:kinesis:${var.kinesis_region}:${data.aws_caller_identity.current.account_id}:stream/${var.kinesis_stream_name}"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_policy" "lambda_kinesis_policy" {
  name        = "${var.role_name}-kinesis-policy"
  description = "Kinesis PutRecord permission for Lambda@Edge"
  policy      = data.aws_iam_policy_document.lambda_kinesis_policy_document.json
}

# Attach defult the AWS-managed AWSLambdaBasicExecutionRole
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach the custom Kinesis policy
resource "aws_iam_role_policy_attachment" "lambda_kinesis_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_kinesis_policy.arn
}
