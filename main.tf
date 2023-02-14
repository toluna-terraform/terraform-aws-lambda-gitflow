locals {
  image_uri             = "${var.ecr_repo_url}:${var.from_env}"
  artifacts_bucket_name = "s3-codepipeline-${var.app_name}-${var.env_type}"
  run_tests             = var.run_integration_tests || var.run_stress_tests ? true : false
  deploy_hooks          = local.run_tests ? "test-framework-manager" : "merge-waiter"
  function_list = { for key, value in var.function_list :
    key => {
      function_name         = value.function_name,
      execution_role_arn    = value.execution_role_arn,
      runtime               = value.runtime,
      cmd                   = try(value.cmd, []),
      workdir               = try(value.workdir, ""),
      entry_point           = try(value.entry_point, []),
      environment_variables = try(value.environment_variables, {})
      tags                  = try(value.tags, {})
      timeout = try(value.timeout, 30)
    }
  }
}

data "external" "current_service_image" {
  program = ["${path.module}/files/get_base_image.sh"]
  query = {
    app_name    = "${var.app_name}"
    image_name  = "${local.image_uri}"
    aws_profile = "${var.aws_profile}"
  }
}

resource "aws_lambda_function" "init_lambdas" {
  for_each      = local.function_list
  function_name = "${each.value.function_name}-${var.env_name}"
  role          = "${each.value.execution_role_arn}"
  image_uri     = data.external.current_service_image.result.image
  publish       = true
  timeout       = each.value.timeout

  environment {
     variables = each.value.environment_variables != {} ? each.value.environment_variables : {ENV_NAME = "${var.env_name}"}
  }

  tags = each.value.tags != {} ? each.value.tags : {}

  image_config {
    command           = each.value.cmd
    entry_point       = each.value.entry_point
    working_directory = each.value.workdir
  }
  vpc_config {
    subnet_ids         = try(var.vpc_config.subnets, [])
    security_group_ids = try(var.vpc_config.security_group_ids, [])
  }
  package_type = "Image"
  depends_on = [
    null_resource.detach_vpc
  ]
}

resource "aws_lambda_alias" "test_lambda_alias" {
  for_each         = local.function_list
  name             = "live"
  function_name    = "${each.value.function_name}-${var.env_name}"
  function_version = aws_lambda_function.init_lambdas[each.key].version
  depends_on = [
    aws_lambda_function.init_lambdas
  ]
}

module "ci-cd-code-pipeline" {
  source                   = "./modules/ci-cd-codepipeline"
  env_name                 = var.env_name
  app_name                 = var.app_name
  pipeline_type            = var.pipeline_type
  source_repository        = var.source_repository
  s3_bucket                = local.artifacts_bucket_name
  build_codebuild_projects = [module.build.attributes.name]
  post_codebuild_projects  = [module.post.attributes.name]
  pre_codebuild_projects   = [module.pre.attributes.name]
  code_deploy_applications = [module.code-deploy.attributes.name]
  function_list            = var.function_list
  depends_on = [
    module.build,
    module.code-deploy,
    module.post,
    module.pre
  ]
}


module "build" {
  source                                = "./modules/build"
  env_name                              = var.env_name
  env_type                              = var.env_type
  codebuild_name                        = "build-${var.app_name}"
  source_repository                     = var.source_repository
  s3_bucket                             = local.artifacts_bucket_name
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  vpc_config                            = var.vpc_config
  environment_variables                 = merge(var.environment_variables, { APPSPEC = templatefile("${path.module}/templates/appspec.json.tpl", { APP_NAME = "${var.app_name}", ENV_TYPE = "${var.env_type}", HOOKS = var.pipeline_type != "dev", HOOK_TYPE = local.deploy_hooks ,PIPELINE_TYPE = var.pipeline_type }) })
  buildspec_file = templatefile("buildspec.yml.tpl",
    { APP_NAME             = var.app_name,
      ENV_TYPE             = var.env_type,
      ENV_NAME             = var.env_name,
      PIPELINE_TYPE        = var.pipeline_type,
      IMAGE_URI            = var.pipeline_type == "dev" ? "${var.ecr_repo_url}:${var.env_name}" : local.image_uri,
      DOCKERFILE_PATH      = var.dockerfile_path,
      ECR_REPO_URL         = var.ecr_repo_url,
      ECR_REPO_NAME        = var.ecr_repo_name,
      ADO_USER             = data.aws_ssm_parameter.ado_user.value,
      ADO_PASSWORD         = data.aws_ssm_parameter.ado_password.value,
      TEST_REPORT          = var.test_report_group,
      CODE_COVERAGE_REPORT = var.coverage_report_group
  })
}


module "code-deploy" {
  source                           = "./modules/codedeploy"
  env_name                         = var.env_name
  env_type                         = var.env_type
  app_name                         = var.app_name
  s3_bucket                        = "s3-codepipeline-${var.app_name}-${var.env_type}"
  termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
  function_list                    = local.function_list
}


module "pre" {
  source                                = "./modules/pre"
  env_name                              = var.env_name
  env_type                              = var.env_type
  codebuild_name                        = "pre-${var.app_name}"
  source_repository                     = var.source_repository
  s3_bucket                             = "s3-codepipeline-${var.app_name}-${var.env_type}"
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  environment_variables                 = merge(var.environment_variables, { APPSPEC = templatefile("${path.module}/templates/appspec.json.tpl", { APP_NAME = "${var.app_name}", ENV_TYPE = "${var.env_type}", HOOKS = var.pipeline_type != "dev", HOOK_TYPE = local.deploy_hooks , PIPELINE_TYPE = var.pipeline_type }) })
  buildspec_file = templatefile("${path.module}/templates/pre_buildspec.yml.tpl",
    { ENV_NAME      = var.env_name,
      APP_NAME      = var.app_name,
      ENV_TYPE      = var.env_type,
      PIPELINE_TYPE = var.pipeline_type,
      FROM_ENV      = var.from_env,
      ECR_REPO_URL  = var.ecr_repo_url,
      ECR_REPO_NAME = var.ecr_repo_name,
      FUNCTION_LIST = var.function_list
  })
  depends_on = [
    aws_lambda_function.init_lambdas
  ]
}


module "post" {
  source                                = "./modules/post"
  env_name                              = var.env_name
  env_type                              = var.env_type
  codebuild_name                        = "post-${var.app_name}"
  source_repository                     = var.source_repository
  s3_bucket                             = "s3-codepipeline-${var.app_name}-${var.env_type}"
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  enable_jira_automation                = var.enable_jira_automation

  buildspec_file = templatefile("${path.module}/templates/post_buildspec.yml.tpl",
    { ECR_REPO_URL           = var.ecr_repo_url,
      ECR_REPO_NAME          = var.ecr_repo_name,
      ENV_NAME               = split("-", var.env_name)[0],
      FROM_ENV               = var.from_env,
      APP_NAME               = var.app_name,
      ENV_TYPE               = var.env_type,
      ENABLE_JIRA_AUTOMATION = var.enable_jira_automation
  })
}

resource "null_resource" "detach_vpc" {
  for_each = local.function_list
  triggers = {
    function    = "${each.value.function_name}-${var.env_name}",
    aws_profile = "${var.aws_profile}",
    env_name    = "${var.env_name}"
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = <<EOT
      aws lambda update-function-configuration --function-name ${self.triggers.function} --vpc-config 'SubnetIds=[],SecurityGroupIds=[]' --profile ${self.triggers.aws_profile}
      sleep 30
      declare -a LAMBDA_VERSIONS=($(aws lambda list-versions-by-function --function-name ${self.triggers.function} --profile ${self.triggers.aws_profile} --query 'Versions[].Version' --output text))
      for i in "$${LAMBDA_VERSIONS[@]}"
      do
        ver=$${i##*( )}
        ver=$${ver%%*()}
        echo "echo deleting $ver"
        aws lambda delete-function --function-name ${self.triggers.function}:$ver --profile ${self.triggers.aws_profile} || aws lambda delete-function --function-name ${self.triggers.function} --profile ${self.triggers.aws_profile} || exit 0
      done
      exit 0
    EOT
  }
  depends_on = [
    module.ci-cd-code-pipeline
  ]
}
