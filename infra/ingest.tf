# ingest.tf — the Lambda that fetches ISS data and writes it to DynamoDB,
# plus its own IAM role scoped to exactly what it needs.

# Zip the ingest source code.
data "archive_file" "ingest_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/ingest/handler.py"
  output_path = "${path.module}/build/ingest.zip"
}

# Execution role (same trust policy as before: only Lambda can assume it).
resource "aws_iam_role" "ingest_exec" {
  name               = "${var.project_name}-ingest-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Basic logging permission (CloudWatch Logs).
resource "aws_iam_role_policy_attachment" "ingest_logs" {
  role       = aws_iam_role.ingest_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# LEAST-PRIVILEGE: allow ONLY PutItem, and ONLY on our specific table.
# Not "all DynamoDB", not "all tables" — just the one action on the one table.
data "aws_iam_policy_document" "ingest_dynamodb" {
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.data.arn]
  }
}

resource "aws_iam_role_policy" "ingest_dynamodb" {
  name   = "${var.project_name}-ingest-dynamodb-write"
  role   = aws_iam_role.ingest_exec.id
  policy = data.aws_iam_policy_document.ingest_dynamodb.json
}

resource "aws_lambda_function" "ingest" {
  function_name = "${var.project_name}-ingest"
  role          = aws_iam_role.ingest_exec.arn
  runtime       = "python3.13"
  handler       = "handler.lambda_handler"
  timeout       = 10 # allow time for the outbound HTTP call

  filename         = data.archive_file.ingest_zip.output_path
  source_code_hash = data.archive_file.ingest_zip.output_base64sha256

  # Pass the table name to the code via an environment variable.
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.data.name
    }
  }
}
