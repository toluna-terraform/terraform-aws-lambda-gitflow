resource "aws_codedeploy_app" "codedeploy_app" {
  #for each function
  name = "lambda-deploy-${var.env_name}"
  compute_platform = "Lambda"
}


resource "aws_codedeploy_deployment_group" "deployment_group" {
  #for each function
  app_name               = aws_codedeploy_app.codedeploy_app.name
  deployment_config_name = "CodeDeployDefault.LambdaAllAtOnce"
  deployment_group_name  = "lambda-deploy-group-${var.env_name}"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
}

resource "aws_iam_role" "codedeploy_role" {
  name = "role-codedeploy-${var.app_name}-${var.env_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "cloudWatch_policy" {
  name = "policy-cloudWatch_policy-${var.env_name}"
  role = aws_iam_role.codedeploy_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "policy-lambda_policy-${var.env_name}"
  role = aws_iam_role.codedeploy_role.id
  policy = data.aws_iam_policy_document.codedeploy_role_policy.json
}

resource "aws_iam_role_policy_attachment" "role-lambda-execution" {
    role       = "${aws_iam_role.codedeploy_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}