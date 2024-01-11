locals {
  app_name               = var.app_name == null ? var.pipeline_config.app_name : var.app_name
  ecr_repo_url           = var.ecr_repo_url == null ? var.pipeline_config.ecr_repo_url : var.ecr_repo_url
  ecr_repo_name          = var.ecr_repo_name == null ? var.pipeline_config.ecr_repo_name : var.ecr_repo_name
  from_env               = var.from_env == null ? var.pipeline_config.from_env : var.from_env
  run_integration_tests  = var.run_integration_tests == null ? var.pipeline_config.run_integration_tests : var.run_integration_tests
  env_type               = var.env_type == null ? var.pipeline_config.env_type : var.env_type
  env_name               = var.env_name == null ? var.pipeline_config.env_name : var.env_name
  pipeline_type          = var.pipeline_type == null ? var.pipeline_config.pipeline_type : var.pipeline_type
  test_report_group      = var.test_report_group == null ? var.pipeline_config.test_report_group : var.test_report_group
  coverage_report_group  = var.coverage_report_group == null ? var.pipeline_config.coverage_report_group : var.coverage_report_group
  image_uri              = var.image_uri == null ? var.pipeline_config.image_uri : var.image_uri
  enable_jira_automation = var.enable_jira_automation == null ? var.pipeline_config.enable_jira_automation : var.enable_jira_automation
  vpc_config = can(var.vpc_config.vpc_id == "not_set") ? merge(
    var.pipeline_config.vpc_config,
    { security_group_ids = var.security_group_ids }
    ) : var.vpc_config == {} ? merge(
    { vpc_id = "", subnets = [] }, { security_group_ids = var.security_group_ids }
    ) : merge(
    { vpc_id = var.vpc_config.vpc_id, subnets = var.vpc_config.subnets }, { security_group_ids = var.security_group_ids }
  )
  artifacts_bucket_name = "s3-codepipeline-${local.app_name}-${local.env_type}"
  run_tests             = local.run_integration_tests || var.run_stress_tests ? true : false
  deploy_hooks          = local.run_tests ? "test-framework-manager" : "merge-waiter"
  function_list = { for key, value in var.function_list :
    key => {
      function_name = value.function_name,
    }
  }
}

module "ci-cd-code-pipeline" {
  source                   = "./modules/ci-cd-codepipeline"
  env_name                 = local.env_name
  app_name                 = local.app_name
  pipeline_type            = local.pipeline_type
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
  env_name                              = local.env_name
  env_type                              = local.env_type
  codebuild_name                        = "build-${local.app_name}"
  source_repository                     = var.source_repository
  s3_bucket                             = local.artifacts_bucket_name
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  vpc_config                            = local.vpc_config
  environment_variables                 = merge(var.environment_variables, { APPSPEC = templatefile("${path.module}/templates/appspec.json.tpl", { APP_NAME = "${local.app_name}", ENV_TYPE = "${local.env_type}", HOOKS = local.pipeline_type != "dev", HOOK_TYPE = local.deploy_hooks, PIPELINE_TYPE = local.pipeline_type }) })
  buildspec_file = templatefile("buildspec.yml.tpl",
    { APP_NAME             = local.app_name,
      ENV_TYPE             = local.env_type,
      ENV_NAME             = local.env_name,
      PIPELINE_TYPE        = local.pipeline_type,
      IMAGE_URI            = local.pipeline_type == "dev" ? "${local.ecr_repo_url}:${local.env_name}" : local.image_uri,
      DOCKERFILE_PATH      = var.dockerfile_path,
      ECR_REPO_URL         = local.ecr_repo_url,
      ECR_REPO_NAME        = local.ecr_repo_name,
      ADO_USER             = data.aws_ssm_parameter.ado_user.value,
      ADO_PASSWORD         = data.aws_ssm_parameter.ado_password.value,
      TEST_REPORT          = local.test_report_group,
      CODE_COVERAGE_REPORT = local.coverage_report_group
  })
}


module "code-deploy" {
  source                           = "./modules/codedeploy"
  env_name                         = local.env_name
  env_type                         = local.env_type
  app_name                         = local.app_name
  s3_bucket                        = "s3-codepipeline-${local.app_name}-${local.env_type}"
  termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
  function_list                    = local.function_list
}


module "pre" {
  source                                = "./modules/pre"
  env_name                              = local.env_name
  env_type                              = local.env_type
  codebuild_name                        = "pre-${local.app_name}"
  source_repository                     = var.source_repository
  s3_bucket                             = "s3-codepipeline-${local.app_name}-${local.env_type}"
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  environment_variables                 = merge(var.environment_variables, { APPSPEC = templatefile("${path.module}/templates/appspec.json.tpl", { APP_NAME = "${local.app_name}", ENV_TYPE = "${local.env_type}", HOOKS = local.pipeline_type != "dev", HOOK_TYPE = local.deploy_hooks, PIPELINE_TYPE = local.pipeline_type }) })
  buildspec_file = templatefile("${path.module}/templates/pre_buildspec.yml.tpl",
    { ENV_NAME      = local.env_name,
      APP_NAME      = local.app_name,
      ENV_TYPE      = local.env_type,
      PIPELINE_TYPE = local.pipeline_type,
      FROM_ENV      = local.from_env,
      ECR_REPO_URL  = local.ecr_repo_url,
      ECR_REPO_NAME = local.ecr_repo_name,
      FUNCTION_LIST = var.function_list
  })
}


module "post" {
  source                                = "./modules/post"
  env_name                              = local.env_name
  env_type                              = local.env_type
  codebuild_name                        = "post-${local.app_name}"
  source_repository                     = var.source_repository
  s3_bucket                             = "s3-codepipeline-${local.app_name}-${local.env_type}"
  privileged_mode                       = true
  environment_variables_parameter_store = var.environment_variables_parameter_store
  enable_jira_automation                = local.enable_jira_automation

  buildspec_file = templatefile("${path.module}/templates/post_buildspec.yml.tpl",
    { ECR_REPO_URL           = local.ecr_repo_url,
      ECR_REPO_NAME          = local.ecr_repo_name,
      ENV_NAME               = split("-", local.env_name)[0],
      FROM_ENV               = local.from_env,
      APP_NAME               = local.app_name,
      ENV_TYPE               = local.env_type,
      ENABLE_JIRA_AUTOMATION = local.enable_jira_automation
  })
}

