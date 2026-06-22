# main.tf — the actual resources. This recreates the Stage 1 hello Lambda,
# but entirely from code (Lambda function + its IAM execution role).

# 1) Zip up the Lambda source code. Terraform builds hello.zip from our .py file.
data "archive_file" "hello_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/hello/handler.py"
  output_path = "${path.module}/build/hello.zip"
}

# 2) Trust policy — "who is allowed to wear this role?"
#    Only the Lambda service can assume it. (Same idea you saw in Stage 1.)
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# 3) The execution role itself.
resource "aws_iam_role" "hello_exec" {
  name               = "${var.project_name}-hello-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# 4) Permissions policy — "what is the role allowed to do?"
#    AWS's managed policy that grants only CloudWatch Logs write access.
#    This is the exact same policy the console auto-attached in Stage 1.
resource "aws_iam_role_policy_attachment" "hello_logs" {
  role       = aws_iam_role.hello_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 5) The Lambda function, wired to the code zip and the role above.
resource "aws_lambda_function" "hello" {
  function_name = "${var.project_name}-hello"
  role          = aws_iam_role.hello_exec.arn
  runtime       = "python3.13"
  handler       = "handler.lambda_handler" # file is handler.py, function is lambda_handler

  filename         = data.archive_file.hello_zip.output_path
  source_code_hash = data.archive_file.hello_zip.output_base64sha256 # redeploy when code changes
}
