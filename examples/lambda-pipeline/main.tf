module "pipeline" {
  source  = "../../"
  # Basic Details
  from_env               = local.env_vars.from_env
  env_name               = local.environment
  app_name               = local.app_name
  env_type               = local.env_vars.env_type
  aws_profile            = local.aws_profile
  source_repository      = "tolunaengineering/my-service"
  trigger_branch         = local.env_vars.pipeline_branch
  pipeline_type          = local.env_vars.pipeline_type
  dockerfile_path        = "service/my-service"
  enable_jira_automation = var.enable_jira_automation

  # ECR
  ecr_registry_id = data.aws_caller_identity.aws_profile.account_id
  ecr_repo_name   = local.ecr_repo_name
  ecr_repo_url    = local.ecr_repo_url

  # Testing
  test_report_group     = data.terraform_remote_state.shared.outputs.TestReport[local.env_name].arn
  coverage_report_group = data.terraform_remote_state.shared.outputs.CodeCoverageReport[local.env_name].arn
  run_integration_tests = local.env_vars.run_integration_tests
  vpc_config = {
    vpc_id             = module.aws_vpc.attributes.vpc_id,
    subnets            = module.aws_vpc.attributes.private_subnets,
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  #Function list
  function_list = [
    {
      function_name      = "${local.app_name}-strawberry"
      cmd                = ["strawberry_my-service.handler"]
      runtime            = "nodejs16.x"
      execution_role_arn = aws_iam_role.lambda_exec.arn
    },
    {
      function_name      = "${local.app_name}-orange"
      cmd                = ["orange_my-service.handler"]
      runtime            = "nodejs16.x"
      execution_role_arn = aws_iam_role.lambda_exec.arn
    }
  ]
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.app_name}-${local.environment}-lambda-exec"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["lambda.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  inline_policy {
    name = "my-service_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["ec2:*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })

  }

}

output "pipeline" {
  value     = module.pipeline.attributes
  sensitive = true
}
