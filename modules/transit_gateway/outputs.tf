output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.this.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.this.arn
}

output "attachment_ids" {
  description = "Map of attachment name → attachment ID"
  value       = { for k, v in aws_ec2_transit_gateway_vpc_attachment.this : k => v.id }
}
