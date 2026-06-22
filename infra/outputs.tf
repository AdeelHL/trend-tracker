# outputs.tf — values Terraform prints after apply, handy for testing.

output "function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.hello.function_name
}

output "function_arn" {
  description = "ARN (unique AWS id) of the Lambda function"
  value       = aws_lambda_function.hello.arn
}

output "ingest_function_name" {
  description = "Name of the ingest Lambda"
  value       = aws_lambda_function.ingest.function_name
}

output "table_name" {
  description = "DynamoDB table storing the time series"
  value       = aws_dynamodb_table.data.name
}
