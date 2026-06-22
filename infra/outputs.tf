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

output "api_base_url" {
  description = "Public base URL of the API (append /latest or /history)"
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "gha_deploy_role_arn" {
  description = "ARN of the role GitHub Actions assumes to deploy"
  value       = aws_iam_role.gha_deploy.arn
}

output "dashboard_url" {
  description = "Public URL of the S3-hosted dashboard"
  value       = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}"
}
