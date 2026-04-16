locals {
  stack_name = "${var.project_name}-${var.environment}"
  build_dir  = "${path.module}/build/${local.stack_name}-api"
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

data "aws_iam_policy_document" "publish_events" {
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
  output_path = "${path.module}/${local.stack_name}-api.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.stack_name}-api-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "${local.stack_name}-api-lambda-logs"
  role = aws_iam_role.lambda_exec.id

  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "publish_events" {
  name = "${local.stack_name}-api-publish-events"
  role = aws_iam_role.lambda_exec.id

  policy = data.aws_iam_policy_document.publish_events.json
}

resource "aws_lambda_function" "ingest" {
  function_name    = "${local.stack_name}-api-ingest"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.lambda_handler"
  runtime          = var.lambda_runtime
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN         = var.sns_topic_arn
      AWS_REGION            = var.aws_region
      AWS_DEFAULT_REGION    = var.aws_region
      AWS_ACCESS_KEY_ID     = var.aws_access_key_id
      AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
      AWS_ENDPOINT_URL      = var.aws_endpoint_url
    }
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.stack_name}-ingest-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "ingest_lambda" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.ingest.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "publish_event" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = var.publish_event_route_key
  target    = "integrations/${aws_apigatewayv2_integration.ingest_lambda.id}"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = var.health_route_key
  target    = "integrations/${aws_apigatewayv2_integration.ingest_lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = var.api_gateway_stage_name
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
