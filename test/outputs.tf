output "test_vpc_id" {
  value = module.test_vpc.vpc_id
}

output "test_vpc_cidr" {
  value = module.test_vpc.vpc_cidr
}

output "test_private_subnet_ids" {
  value = module.test_vpc.private_subnet_ids
}

output "test_s3_vpce_id" {
  description = "Feed this into shared/variables.tf test_s3_vpce_id"
  value       = module.test_vpc.s3_vpce_id
}

output "test_dynamodb_vpce_id" {
  description = "Feed this into shared/variables.tf test_dynamodb_vpce_id"
  value       = module.test_vpc.dynamodb_vpce_id
}

output "shared_nlb_vpce_dns" {
  description = "DNS name of the PrivateLink endpoint reaching the shared NLB"
  value       = aws_vpc_endpoint.shared_nlb.dns_entry[0]["dns_name"]
}
