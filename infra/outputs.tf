# outputs.tf — values Terraform prints after apply, handy for testing.

output "function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.hello.function_name
}

output "function_arn" {
  description = "ARN (unique AWS id) of the Lambda function"
  value       = aws_lambda_function.hello.arn
}
