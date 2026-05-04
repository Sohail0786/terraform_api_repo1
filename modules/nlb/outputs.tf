output "nlb_arn" {
  value = aws_lb.this.arn
}

output "nlb_dns_name" {
  value = aws_lb.this.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "endpoint_service_name" {
  description = "PrivateLink service name for dev/test to consume"
  value       = aws_vpc_endpoint_service.this.service_name
}
