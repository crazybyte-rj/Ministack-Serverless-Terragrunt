output "lambda_function_name" {
  value       = aws_lambda_function.dlq_consumer.function_name
  description = "DLQ consumer Lambda function name"
}

output "lambda_function_arn" {
  value       = aws_lambda_function.dlq_consumer.arn
  description = "DLQ consumer Lambda function ARN"
}
