<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_external"></a> [external](#provider\_external) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_build"></a> [build](#module\_build) | ./modules/build | n/a |
| <a name="module_ci-cd-code-pipeline"></a> [ci-cd-code-pipeline](#module\_ci-cd-code-pipeline) | ./modules/ci-cd-codepipeline | n/a |
| <a name="module_code-deploy"></a> [code-deploy](#module\_code-deploy) | ./modules/codedeploy | n/a |
| <a name="module_post"></a> [post](#module\_post) | ./modules/post | n/a |
| <a name="module_pre"></a> [pre](#module\_pre) | ./modules/pre | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_lambda_alias.test_lambda_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_alias) | resource |
| [aws_lambda_function.init_lambdas](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [null_resource.detach_vpc](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.ado_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.ado_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [external_external.current_service_image](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | n/a | `string` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | n/a | `string` | n/a | yes |
| <a name="input_coverage_report_group"></a> [coverage\_report\_group](#input\_coverage\_report\_group) | n/a | `string` | n/a | yes |
| <a name="input_dockerfile_path"></a> [dockerfile\_path](#input\_dockerfile\_path) | n/a | `string` | n/a | yes |
| <a name="input_ecr_registry_id"></a> [ecr\_registry\_id](#input\_ecr\_registry\_id) | n/a | `string` | n/a | yes |
| <a name="input_ecr_repo_name"></a> [ecr\_repo\_name](#input\_ecr\_repo\_name) | n/a | `string` | n/a | yes |
| <a name="input_ecr_repo_url"></a> [ecr\_repo\_url](#input\_ecr\_repo\_url) | n/a | `string` | n/a | yes |
| <a name="input_enable_jira_automation"></a> [enable\_jira\_automation](#input\_enable\_jira\_automation) | flag to indicate if Jira automation is enabled | `bool` | `false` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | n/a | `string` | n/a | yes |
| <a name="input_env_type"></a> [env\_type](#input\_env\_type) | n/a | `string` | n/a | yes |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | n/a | `map(string)` | `{}` | no |
| <a name="input_environment_variables_parameter_store"></a> [environment\_variables\_parameter\_store](#input\_environment\_variables\_parameter\_store) | n/a | `map(string)` | <pre>{<br>  "ADO_PASSWORD": "/app/ado_password",<br>  "ADO_USER": "/app/ado_user"<br>}</pre> | no |
| <a name="input_from_env"></a> [from\_env](#input\_from\_env) | n/a | `string` | n/a | yes |
| <a name="input_function_list"></a> [function\_list](#input\_function\_list) | n/a | `list` | `[]` | no |
| <a name="input_pipeline_type"></a> [pipeline\_type](#input\_pipeline\_type) | n/a | `string` | n/a | yes |
| <a name="input_run_integration_tests"></a> [run\_integration\_tests](#input\_run\_integration\_tests) | n/a | `bool` | `false` | no |
| <a name="input_run_stress_tests"></a> [run\_stress\_tests](#input\_run\_stress\_tests) | n/a | `bool` | `false` | no |
| <a name="input_source_repository"></a> [source\_repository](#input\_source\_repository) | n/a | `string` | n/a | yes |
| <a name="input_termination_wait_time_in_minutes"></a> [termination\_wait\_time\_in\_minutes](#input\_termination\_wait\_time\_in\_minutes) | n/a | `number` | `120` | no |
| <a name="input_test_report_group"></a> [test\_report\_group](#input\_test\_report\_group) | n/a | `string` | n/a | yes |
| <a name="input_trigger_branch"></a> [trigger\_branch](#input\_trigger\_branch) | n/a | `string` | n/a | yes |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | n/a | `map` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_attributes"></a> [attributes](#output\_attributes) | All lambda output parameters |
<!-- END_TF_DOCS -->