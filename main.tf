provider "aws" {
  alias = "region"
}

data "aws_region" "current" {}

resource "aws_lambda_function" "lambda_function" {
  filename      = local.lambda_payload_file
  function_name = "terraform-lambda-secrets-test"
  description   = "Test lamda to test private VPC lambda and AWS secrets connections"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  source_code_hash = data.archive_file.archive.output_base64sha256

  tags = {
    Name = "terraform lambda module"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.policy_document_assume_lambda_role.json
}

resource "aws_iam_policy" "foobar_secrets_lambda_exec_policy" {
  name   = "allow-lambda-exec-policy"
  policy = data.aws_iam_policy_document.policy_document_exec.json
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.foobar_secrets_policy.arn
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_lambda_vpc_access_execution" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_secretsmanager_secret" "foobar_secrets" {
  name        = "SECRETS_FOOBAR"
  description = "Secrets for testing, not actually sensitive"
}

resource "aws_secretsmanager_secret_version" "foobar_secrets_version" {
  secret_id = aws_secretsmanager_secret.foobar_secrets.id


  secret_string = jsonencode({
    user     = "foobar_user"
    password = "foobar"
  })
}

resource "aws_iam_policy" "foobar_secrets_policy" {
  name        = "LambdaSecretsAccessPolicy"
  description = "Allows lambda to read secret"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret.foobar_secrets.arn
      }
    ]
  })
}


# data declarations

data "archive_file" "archive" {
  output_path = local.lambda_payload_file
  type        = "zip"
  source_dir  = "./src"
  excludes    = ["node_modules"]
}

data "aws_iam_policy_document" "policy_document_assume_lambda_role" {
  statement {
    sid    = "TfLambdaAssumeRole"
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "policy_document_exec" {
  version = "2012-10-17"

  statement {
    sid    = "TfLambdaExecPermission"
    effect = "Allow"

    resources = ["*"]

    actions = ["lambda:InvokeFunction"]
  }
}
