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
  # vpc_config {
  #   security_group_ids = []
  #   subnet_ids = module.vpc.private_subnets
  # }

  vpc_config {
    subnet_ids         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
    security_group_ids = [aws_default_security_group.default_lambda_security_group.id]
  }

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

# vpc
module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  azs             = data.aws_availability_zones.azs.names
}

# security group

resource "aws_default_security_group" "default_lambda_security_group" {
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol    = -1
    self        = true
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "poc-lambda-secrets-default-security-group"
    CreatedBy = "Terraform"
  }
}