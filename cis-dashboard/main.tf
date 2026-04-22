data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# CIS Benchmark alarms
# Creates all 25+ CIS metric filters + CloudWatch alarms from the CloudTrail
# log group. alarm_actions and ok_actions are empty by default so no SNS
# topic or Lambda is required.
# ---------------------------------------------------------------------------
module "cis_alarms" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/cis-alarms"
  version = "~> 5.0"

  log_group_name = var.cloudtrail_log_group_name
  name_prefix    = "${var.name_prefix}-"
  alarm_actions  = var.alarm_actions
  ok_actions     = var.ok_actions
  tags           = var.tags
}

# ---------------------------------------------------------------------------
# Dashboard layout helpers
# ---------------------------------------------------------------------------
locals {
  widget_width    = 6
  widget_height   = 3
  widgets_per_row = 4

  # Flatten the map of alarms produced by the cis-alarms module into a list
  # of alarm names so we can index them for x/y positioning.
  alarm_names = [for k, v in module.cis_alarms.alarms : v.alarm_name]

  alarm_widgets = [
    for idx, alarm_name in local.alarm_names : {
      type   = "alarm"
      x      = (idx % local.widgets_per_row) * local.widget_width
      y      = floor(idx / local.widgets_per_row) * local.widget_height
      width  = local.widget_width
      height = local.widget_height
      properties = {
        title  = alarm_name
        alarms = ["arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:${alarm_name}"]
        period = var.dashboard_period_seconds
        view   = "timeSeries"
        stat   = "Sum"
      }
    }
  ]
}

# ---------------------------------------------------------------------------
# CloudWatch dashboard
# ---------------------------------------------------------------------------
module "cis_dashboard" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/dashboard"
  version = "~> 5.0"

  name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = local.alarm_widgets
  })
}
