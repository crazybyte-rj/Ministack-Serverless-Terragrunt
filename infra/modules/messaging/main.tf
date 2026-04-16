locals {
  stack_name = "${var.project_name}-${var.environment}"
}

data "aws_iam_policy_document" "events_queue" {
  statement {
    sid       = "AllowSnsSendMessage"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.events.arn]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.events.arn]
    }
  }
}

resource "aws_sns_topic" "events" {
  name = "${local.stack_name}-events"
}

resource "aws_sqs_queue" "events_dlq" {
  name = "${local.stack_name}-events-dlq"
}

resource "aws_sqs_queue" "events" {
  name = "${local.stack_name}-events"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.events_dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })
}

resource "aws_sqs_queue_policy" "events" {
  queue_url = aws_sqs_queue.events.id

  policy = data.aws_iam_policy_document.events_queue.json
}

resource "aws_sns_topic_subscription" "events_queue" {
  topic_arn            = aws_sns_topic.events.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.events.arn
  raw_message_delivery = true
}
