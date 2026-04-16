locals {
  stack_name = "${var.project_name}-${var.environment}"
  build_dir  = "${path.module}/build/${local.stack_name}-worker"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "consume_events_queue" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [var.sqs_queue_arn]
  }
}

data "aws_iam_policy_document" "write_events" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [var.dynamodb_table_arn]
  }
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
${var.lambda_build_python} -m pip install -r "${path.module}/lambda_src/requirements.txt" -t "${local.build_dir}" --upgrade
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

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "${local.stack_name}-worker-lambda-logs"
  role = aws_iam_role.lambda_exec.id

  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "consume_events_queue" {
  name = "${local.stack_name}-worker-consume-events"
  role = aws_iam_role.lambda_exec.id

  policy = data.aws_iam_policy_document.consume_events_queue.json
}

resource "aws_iam_role_policy" "write_events" {
  name = "${local.stack_name}-worker-write-events"
  role = aws_iam_role.lambda_exec.id

  policy = data.aws_iam_policy_document.write_events.json
}

resource "aws_lambda_function" "worker" {
  function_name    = "${local.stack_name}-worker"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = var.lambda_runtime
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME   = var.dynamodb_table_name
      SQS_QUEUE_URL         = var.sqs_queue_url
      AWS_REGION            = var.aws_region
      AWS_DEFAULT_REGION    = var.aws_region
      AWS_ACCESS_KEY_ID     = var.aws_access_key_id
      AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
      AWS_ENDPOINT_URL      = var.aws_endpoint_url
    }
  }
}

resource "aws_lambda_event_source_mapping" "from_sqs" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.worker.arn
  batch_size       = var.lambda_batch_size
  enabled          = true
  function_response_types = var.lambda_function_response_types
}
