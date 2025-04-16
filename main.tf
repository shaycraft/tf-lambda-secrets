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

resource "aws_iam_policy" "policy" {
  name   = "allow-lambda-exec-policy"
  policy = data.aws_iam_policy_document.policy_document_exec.json
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_lambda_vpc_access_execution" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
