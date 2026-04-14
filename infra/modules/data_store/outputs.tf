output "table_name" {
  value       = aws_dynamodb_table.events.name
  description = "DynamoDB table name"
}

output "table_arn" {
  value       = aws_dynamodb_table.events.arn
  description = "DynamoDB table ARN"
}

output "dlq_table_name" {
  value       = aws_dynamodb_table.dlq_events.name
  description = "DynamoDB DLQ events table name"
}

output "dlq_table_arn" {
  value       = aws_dynamodb_table.dlq_events.arn
  description = "DynamoDB DLQ events table ARN"
}
