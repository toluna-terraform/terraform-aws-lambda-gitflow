output "attributes" {
    value = { for key, value in aws_lambda_function.init_lambdas : value.function_name => value }
    description = "All lambda output parameters"
}