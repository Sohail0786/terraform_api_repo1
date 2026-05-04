output "transit_gateway_id" {
  description = "Share with dev and test workspaces"
  value       = module.tgw.transit_gateway_id
}

output "shared_vpc_id" {
  value = module.shared_vpc.vpc_id
}

output "shared_vpc_cidr" {
  value = module.shared_vpc.vpc_cidr
}

output "nlb_dns_name" {
  description = "Internal DNS name of the NLB"
  value       = module.nlb.nlb_dns_name
}

output "nlb_endpoint_service_name" {
  description = "PrivateLink service name – set this as VPC endpoint in dev/test"
  value       = module.nlb.endpoint_service_name
}

output "api_invoke_url" {
  description = "Private API Gateway stage invoke URL"
  value       = module.api_gateway.invoke_url
}

output "s3_bucket_name" {
  value = module.s3.bucket_id
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "lambda_function_name" {
  value = module.lambda.function_name
}
