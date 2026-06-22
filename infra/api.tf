# api.tf — the Lambda that reads from DynamoDB, plus its read-only IAM role.

data "archive_file" "api_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/api/handler.py"
  output_path = "${path.module}/build/api.zip"
}

resource "aws_iam_role" "api_exec" {
  name               = "${var.project_name}-api-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "api_logs" {
  role       = aws_iam_role.api_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# LEAST-PRIVILEGE: this role may ONLY run Query, and ONLY on our table.
# Compare to the ingest role, which could only PutItem. Neither can do the other.
data "aws_iam_policy_document" "api_dynamodb" {
  statement {
    actions   = ["dynamodb:Query"]
    resources = [aws_dynamodb_table.data.arn]
  }
}

resource "aws_iam_role_policy" "api_dynamodb" {
  name   = "${var.project_name}-api-dynamodb-read"
  role   = aws_iam_role.api_exec.id
  policy = data.aws_iam_policy_document.api_dynamodb.json
}

resource "aws_lambda_function" "api" {
  function_name = "${var.project_name}-api"
  role          = aws_iam_role.api_exec.arn
  runtime       = "python3.13"
  handler       = "handler.lambda_handler"
  timeout       = 10

  filename         = data.archive_file.api_zip.output_path
  source_code_hash = data.archive_file.api_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.data.name
    }
  }
}
