data "aws_iam_policy_document" "lambda_policy_document" {
    version = "2012-10-17"

    statement {
      effect = "Allow"
      actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"]
    }
}

data "aws_iam_policy_document" "assume_role_policy" {
    statement {
      effect = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type = "Service"
        identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
      }
    }
}

resource "aws_iam_role" "lambda_role" {
  name = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.role_name}-lambda_policy"
  description = "Iam policy for lambda edge"
  policy = data.aws_iam_policy_document.lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attach" {
  role = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
