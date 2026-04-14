output "worker_lambda_name" {
  value       = aws_lambda_function.worker.function_name
  description = "Worker Lambda function name"
}
