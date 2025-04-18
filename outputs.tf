output "lambda_arn" {
  value = aws_lambda_function.lambda_function.arn
}

output "lambda_name" {
  value = aws_lambda_function.lambda_function.function_name
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}