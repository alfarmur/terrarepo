provider "aws" {
  region = "us-east-1"
}

# 1️⃣ Create the Lambda function
resource "aws_lambda_function" "example" {
  function_name = "example-scheduled-lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 300
  memory_size   = 128

  filename         = "lambda_function.zip" # Path to your packaged code
  source_code_hash = filebase64sha256("lambda_function.zip")

  # Ensure log group is created before Lambda executes
  depends_on = [aws_cloudwatch_log_group.lambda_logs]
}

# 2️⃣ IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 3️⃣ Attach basic execution policy (includes CloudWatch Logs write access)
resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ✅ 3.1️⃣ (Optional) Add explicit CloudWatch Logs policy
# This is redundant with AWSLambdaBasicExecutionRole but shown for clarity
resource "aws_iam_role_policy" "custom_cloudwatch_access" {
  name = "custom-cloudwatch-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ✅ 4️⃣ CloudWatch Log Group (explicitly create it)
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/example-scheduled-lambda"
  retention_in_days = 7
}

# 5️⃣ Create EventBridge rule (schedule)
resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "every-five-minutes"
  description         = "Trigger Lambda every 5 minutes"
  schedule_expression = "rate(5 minutes)"
}

# 6️⃣ Add the Lambda target
resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "lambda"
  arn       = aws_lambda_function.example.arn
}

# 7️⃣ Allow EventBridge to invoke the Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}
