provider "aws" {
  region = "us-east-1"  
}

resource "aws_lambda_function" "s3_logger" {
  function_name = "s3-logger"
  handler      = "lambda_function.handler"
  runtime      = "python3.8"
  filename     = "${path.module}/lambda_function.py"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.py")

  role = aws_iam_role.lambda_execution_role.arn

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.logging_bucket.id
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "s3-logger-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  roles      = [aws_iam_role.lambda_execution_role.name]
}

resource "aws_s3_bucket" "logging_bucket" {
  bucket = "my-logging-bucket-test"  
  acl    = "private"
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name        = "s3-logger-schedule"
  description = "Schedule for running the Lambda function"
  schedule_expression = "cron(0 2 ? * SAT#1 *)"

  depends_on = [aws_lambda_function.s3_logger]

  event_pattern = jsonencode({
    source = ["aws.s3"],
    detail = {
      eventName = ["PutObject"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "s3-logger-target"
  arn       = aws_lambda_function.s3_logger.arn
}