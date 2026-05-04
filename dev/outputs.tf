output "dev_vpc_id" {
  value = module.dev_vpc.vpc_id
}

output "dev_vpc_cidr" {
  value = module.dev_vpc.vpc_cidr
}

output "dev_private_subnet_ids" {
  value = module.dev_vpc.private_subnet_ids
}

output "dev_s3_vpce_id" {
  description = "Feed this into shared/variables.tf dev_s3_vpce_id"
  value       = module.dev_vpc.s3_vpce_id
}

output "dev_dynamodb_vpce_id" {
  description = "Feed this into shared/variables.tf dev_dynamodb_vpce_id"
  value       = module.dev_vpc.dynamodb_vpce_id
}

output "shared_nlb_vpce_dns" {
  description = "DNS name of the PrivateLink endpoint reaching the shared NLB"
  value       = aws_vpc_endpoint.shared_nlb.dns_entry[0]["dns_name"]
}
