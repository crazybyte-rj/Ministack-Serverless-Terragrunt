output "sns_topic_arn" {
  value       = aws_sns_topic.events.arn
  description = "SNS topic ARN"
}

output "sqs_queue_arn" {
  value       = aws_sqs_queue.events.arn
  description = "SQS queue ARN"
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.events.id
  description = "SQS queue URL"
}

output "dlq_queue_arn" {
  value       = aws_sqs_queue.events_dlq.arn
  description = "SQS DLQ queue ARN"
}

output "dlq_queue_url" {
  value       = aws_sqs_queue.events_dlq.id
  description = "SQS DLQ queue URL"
}
