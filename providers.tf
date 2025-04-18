provider "aws" {
  region = "us-west-2"
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