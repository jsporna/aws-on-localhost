variable "lambda_name" {
  type = string
}

resource "aws_s3_bucket" "lambda" {
  bucket = var.lambda_name
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = var.lambda_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.lambda.arn,
      "${aws_s3_bucket.lambda.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEventes",
      "logs:CreateLogGroup",
      "logs:CreateLogStream"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  policy = data.aws_iam_policy_document.lambda_policy.json
  role   = aws_iam_role.lambda.id
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../lambda/handler.py"
  output_path = "../lambda/package.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      APPLICATION_TABLE     = aws_dynamodb_table.application.name
      INPUT_S3_BUCKET       = aws_s3_bucket.lambda.bucket
      OUTPUT_DYNAMODB_TABLE = aws_dynamodb_table.application.name
    }
  }
}

resource "aws_s3_bucket_notification" "lambda" {
  bucket = aws_s3_bucket.lambda.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "lambda" {
  statement_id  = "AllowS3BucketToInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.lambda.arn
}
