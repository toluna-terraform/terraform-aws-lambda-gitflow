variable "pipeline_config" {
}

variable "env_name" {
  type     = string
  default  = null
}

variable "from_env" {
  type     = string
  default  = null
}

variable "app_name" {
  type     = string
  default  = null
}

variable "env_type" {
  type     = string
  default  = null
}

variable "aws_profile" {
  type     = string
  default  = null
}

variable "run_integration_tests" {
  type     = bool
  default  = null
}

variable "run_stress_tests" {
  type    = bool
  default = false
}

variable "ecr_repo_url" {
  type     = string
  default  = null
}

variable "image_uri" {
  type     = string
  default  = null
}

variable "ecr_repo_name" {
  type     = string
  default  = null
}

variable "source_repository" {
  type     = string
  default  = null
}

variable "trigger_branch" {
  type     = string
  default  = null
}

variable "dockerfile_path" {
  type     = string
  default  = null
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
  type    = string
  default = null
}

variable "termination_wait_time_in_minutes" {
  default = 120
}

variable "test_report_group" {
  type     = string
  default  = null
}

variable "coverage_report_group" {
  type     = string
  default  = null
}

variable "enable_jira_automation" {
  type        = bool
  description = "flag to indicate if Jira automation is enabled"
  default     = null
}

variable "function_list" {
  default = []
}
