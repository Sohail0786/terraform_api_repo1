output "asg_name" {
  value = aws_autoscaling_group.nginx.name
}

output "security_group_id" {
  value = aws_security_group.nginx.id
}

output "launch_template_id" {
  value = aws_launch_template.nginx.id
}
