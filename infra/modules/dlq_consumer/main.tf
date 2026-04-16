locals {
  stack_name = "${var.project_name}-${var.environment}"
  build_dir  = "${path.module}/build/${local.stack_name}-dlq"
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

data "aws_iam_policy_document" "consume_dlq" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [var.dlq_queue_arn]
  }
}

data "aws_iam_policy_document" "write_dlq_events" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [var.dlq_table_arn]
  }
}

data "aws_iam_policy_document" "publish_alerts" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
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
  output_path = "${path.module}/${local.stack_name}-dlq.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.stack_name}-dlq-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "${local.stack_name}-dlq-lambda-logs"
  role = aws_iam_role.lambda_exec.id

  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "consume_dlq" {
  name = "${local.stack_name}-dlq-consume-queue"
  role = aws_iam_role.lambda_exec.id

  policy = data.aws_iam_policy_document.consume_dlq.json
}

resource "aws_iam_role_policy" "write_dlq_events" {
  name = "${local.stack_name}-dlq-write-events"
  role = aws_iam_role.lambda_exec.id

  policy = data.aws_iam_policy_document.write_dlq_events.json
}

resource "aws_iam_role_policy" "publish_alerts" {
  name = "${local.stack_name}-dlq-publish-alerts"
  role = aws_iam_role.lambda_exec.id

  policy = data.aws_iam_policy_document.publish_alerts.json
}

resource "aws_lambda_function" "dlq_consumer" {
  function_name    = "${local.stack_name}-dlq-consumer"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = var.lambda_runtime
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = var.lambda_timeout

  environment {
    variables = {
      DLQ_TABLE_NAME        = var.dlq_table_name
      SNS_ALERT_TOPIC       = var.sns_topic_arn
      AWS_REGION            = var.aws_region
      AWS_DEFAULT_REGION    = var.aws_region
      AWS_ACCESS_KEY_ID     = var.aws_access_key_id
      AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
      AWS_ENDPOINT_URL      = var.aws_endpoint_url
    }
  }
}

resource "aws_lambda_event_source_mapping" "from_dlq" {
  event_source_arn = var.dlq_queue_arn
  function_name    = aws_lambda_function.dlq_consumer.arn
  batch_size       = var.lambda_batch_size
  enabled          = true
  maximum_batching_window_in_seconds = var.maximum_batching_window_in_seconds
}
