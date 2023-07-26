output "function_arn" {
    description = "Lambda function arn"
    value = aws_lambda_function.lambda.arn
}

output "name" {
  description = "Lambda function name"
  value = aws_lambda_function.lambda.function_name
}