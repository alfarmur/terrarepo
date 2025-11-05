provider "aws" {
  region = "us-east-1"
}

# 1️⃣ Create an S3 bucket to store the Lambda deployment package
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "yabkt-example-lambda-code"  # must be globally unique
}

# 2️⃣ Upload the Lambda zip file to S3
# (The zip file must exist locally first)
resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "lambda_function.zip"
  source = "D:/terraform/terrarepo/day9-lambda-s3/lambda_function.zip" # local path to your zip file
  etag   = filemd5("lambda_function.zip")
}

# 3️⃣ IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role_s3"

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

# 4️⃣ Attach basic execution policy for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ✅ 5️⃣ (Optional) Add explicit CloudWatch log access
resource "aws_iam_role_policy" "custom_cloudwatch_access" {
  name = "custom-cloudwatch-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

# ✅ 6️⃣ Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/example-scheduled-lambda"
  retention_in_days = 14
}

# 7️⃣ Create the Lambda function (source from S3)
resource "aws_lambda_function" "example" {
  function_name = "example-scheduled-lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 300
  memory_size   = 128

  # Source code from S3
  s3_bucket = aws_s3_bucket.lambda_bucket.bucket
  s3_key    = aws_s3_object.lambda_zip.key

  # Hash to detect changes
  source_code_hash = filebase64sha256("lambda_function.zip")

  depends_on = [aws_cloudwatch_log_group.lambda_logs]
}

# 8️⃣ Create EventBridge rule (schedule trigger)
resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = "every-five-minutes"
  description         = "Trigger Lambda every 5 minutes"
  schedule_expression = "rate(5 minutes)"
}

# 9️⃣ Add EventBridge target
resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "lambda"
  arn       = aws_lambda_function.example.arn
}

# 🔟 Allow EventBridge to invoke the Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}