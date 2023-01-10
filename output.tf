output "attributes" {
    value = { for key, value in aws_lambda_function.init_lambdas : key => value }
    description = "All lambda output parameters"
    sensitive = true
}