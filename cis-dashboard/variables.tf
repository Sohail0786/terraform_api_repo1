variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
  default     = "cis"
}

variable "cloudtrail_log_group_name" {
  description = "Name of the CloudWatch Log Group that CloudTrail writes to (e.g. 'aws-cloudtrail-logs')"
  type        = string
}

variable "alarm_actions" {
  description = "List of ARNs to notify when any CIS alarm fires (leave empty to disable actions)"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of ARNs to notify when a CIS alarm recovers"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "dashboard_name" {
  description = "Name for the CloudWatch dashboard"
  type        = string
  default     = "CIS-Alarms-Dashboard"
}

variable "dashboard_period_seconds" {
  description = "Default period (seconds) for dashboard widgets"
  type        = number
  default     = 300
}
