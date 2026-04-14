locals {
  stack_name = "${var.project_name}-${var.environment}"
  build_dir  = "${path.module}/build/${local.stack_name}-worker"
}

resource "null_resource" "prepare_lambda_package" {
  triggers = {
    handler_hash      = filesha256("${path.module}/lambda_src/handler.py")
    requirements_hash = filesha256("${path.module}/lambda_src/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<EOT
set -e
rm -rf "${local.build_dir}"
mkdir -p "${local.build_dir}"
cp -R "${path.module}/lambda_src/." "${local.build_dir}/"
python3 -m pip install -r "${path.module}/lambda_src/requirements.txt" -t "${local.build_dir}" --upgrade
EOT
  }
}

data "archive_file" "lambda_zip" {
  depends_on  = [null_resource.prepare_lambda_package]
  type        = "zip"
  source_dir  = local.build_dir
  output_path = "${path.module}/${local.stack_name}-worker.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.stack_name}-worker-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.stack_name}-worker-lambda-policy"
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
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

resource "aws_lambda_function" "worker" {
  function_name    = "${local.stack_name}-worker"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      SQS_QUEUE_URL       = var.sqs_queue_url
      AWS_REGION          = "us-east-1"
      AWS_DEFAULT_REGION  = "us-east-1"
      AWS_ACCESS_KEY_ID   = "test"
      AWS_SECRET_ACCESS_KEY = "test"
      AWS_ENDPOINT_URL    = "http://localhost:4566"
    }
  }
}

resource "aws_lambda_event_source_mapping" "from_sqs" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.worker.arn
  batch_size       = 10
  enabled          = true
  function_response_types = ["ReportBatchItemFailures"]
}
