variable "project" {
  type        = string
  description = "Project name prefix"
  default     = "myapp"
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID (used in globally-unique resource names)"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

# ── Shared VPC ────────────────────────────────────────────────────────────────

variable "shared_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "shared_private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

# ── VPC Endpoint IDs from dev and test (passed in after those envs are built) --

variable "dev_s3_vpce_id" {
  type        = string
  description = "S3 Gateway VPCE ID from the dev VPC"
  default     = ""
}

variable "dev_dynamodb_vpce_id" {
  type        = string
  description = "DynamoDB Gateway VPCE ID from the dev VPC"
  default     = ""
}

variable "test_s3_vpce_id" {
  type        = string
  description = "S3 Gateway VPCE ID from the test VPC"
  default     = ""
}

variable "test_dynamodb_vpce_id" {
  type        = string
  description = "DynamoDB Gateway VPCE ID from the test VPC"
  default     = ""
}
