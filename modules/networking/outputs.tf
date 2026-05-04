output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

output "vpc_endpoint_sg_id" {
  description = "Security group ID used by VPC endpoints"
  value       = aws_security_group.vpc_endpoint.id
}

output "execute_api_vpce_id" {
  description = "ID of the execute-api Interface VPC Endpoint"
  value       = aws_vpc_endpoint.interface["com.amazonaws.${var.aws_region}.execute-api"].id
}

output "s3_vpce_id" {
  description = "S3 Gateway VPC Endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_vpce_id" {
  description = "DynamoDB Gateway VPC Endpoint ID"
  value       = aws_vpc_endpoint.dynamodb.id
}
