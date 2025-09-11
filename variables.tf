variable "env_name" {
  type = string
}

variable "from_env" {
  type = string
}

variable "app_name" {
  type = string
}

variable "env_type" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "run_integration_tests" {
  type    = bool
  default = false
}

variable "run_stress_tests" {
  type    = bool
  default = false
}

variable "ecr_repo_url" {
  type = string
}

variable "ecr_registry_id" {
  type = string
}

variable "ecr_repo_name" {
  type = string
}

variable "source_repository" {
  type = string
}

variable "trigger_branch" {
  type = string
}

variable "dockerfile_path" {
    type = string
}

variable "environment_variables_parameter_store" {
  type = map(string)
  default = {
    "ADO_USER"     = "/app/ado_user",
    "ADO_PASSWORD" = "/app/ado_password"
  }
}

variable "environment_variables" {
  type = map(string)
  default = {
  }
}

variable "pipeline_type" {
  type = string
}

variable "termination_wait_time_in_minutes" {
  default = 120
}

variable "test_report_group" {
  type = string
}

variable "coverage_report_group" {
  type = string
}

variable "enable_jira_automation" {
  type        = bool
  description = "flag to indicate if Jira automation is enabled"
  default     = false
}

variable "vpc_config" {
  default = {}
}

variable "function_list" {
  default     = []
}

variable "tribe" {
  type = string
}