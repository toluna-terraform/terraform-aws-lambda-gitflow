variable "pipeline_config" {
  type = map(string)
}

variable "env_name" {
  type = string
  default = null
  nullable = true
}

variable "from_env" {
  type = string
  default = null
  nullable = true
}

variable "app_name" {
  type = string
  default = null
  nullable = true
}

variable "env_type" {
  type = string
  default = null
  nullable = true
}

variable "aws_profile" {
  type = string
  default = null
  nullable = true
}

variable "run_integration_tests" {
  type    = bool
  default = null
  nullable = true
}

variable "run_stress_tests" {
  type    = bool
  default = false
}

variable "ecr_repo_url" {
  type = string
  default = null
  nullable = true
}

variable "image_uri" {
  type = string
  default = null
  nullable = true
}

variable "ecr_repo_name" {
  type = string
  default = null
  nullable = true
}

variable "source_repository" {
  type = string
  default = null
  nullable = true
}

variable "trigger_branch" {
  type = string
  default = null
  nullable = true
}

variable "dockerfile_path" {
    type = string
    default = null
    nullable = true
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
  default = null
  #nullable = true
}

variable "termination_wait_time_in_minutes" {
  default = 120
}

variable "test_report_group" {
  type = string
  default = null
  nullable = true
}

variable "coverage_report_group" {
  type = string
  default = null
  nullable = true
}

variable "enable_jira_automation" {
  type        = bool
  description = "flag to indicate if Jira automation is enabled"
  default = null
  nullable = true
}

variable "vpc_config" {
  default = {}
}

variable "function_list" {
  default     = {}
}
