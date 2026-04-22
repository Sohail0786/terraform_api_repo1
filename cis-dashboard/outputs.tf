output "cis_alarm_arns" {
  description = "Map of CIS alarm key to alarm ARN"
  value       = { for k, v in module.cis_alarms.alarms : k => v.alarm_arn }
}

output "dashboard_arn" {
  description = "ARN of the CIS CloudWatch dashboard"
  value       = module.cis_dashboard.dashboard_arn
}

output "dashboard_url" {
  description = "Direct URL to the CloudWatch dashboard in the AWS console"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home#dashboards:name=${var.dashboard_name}"
}
