output "invoke_arns" {
    value = aws_lambda_function.init_lambdas.invoke_arn
}