variable "env_name" {
  type = string
}

variable "env_type" {
  type = string
}

variable "app_name" {
  type = string
}

variable "s3_bucket" {
  type = string
}

variable "termination_wait_time_in_minutes" {
  default = 120
}