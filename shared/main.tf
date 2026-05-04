###############################################################################
# Shared Services – root configuration
# Deploys: VPC, Transit Gateway, NLB, Private API GW, Lambda, S3, DynamoDB,
#          Nginx proxy.  Dev and test VPCs connect here via Transit Gateway.
###############################################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # Uncomment and configure for remote state:
  # backend "s3" {
  #   bucket         = "my-tf-state-bucket"
  #   key            = "shared/terraform.tfstate"
  #   region         = "eu-west-2"
  #   dynamodb_table = "tf-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

# ── Shared VPC ────────────────────────────────────────────────────────────────

module "shared_vpc" {
  source = "../modules/networking"

  name_prefix          = "${var.project}-shared"
  vpc_cidr             = var.shared_vpc_cidr
  private_subnet_cidrs = var.shared_private_subnet_cidrs
  availability_zones   = var.availability_zones
  aws_region           = var.aws_region
  tags                 = local.common_tags
}

# ── Transit Gateway ───────────────────────────────────────────────────────────

module "tgw" {
  source = "../modules/transit_gateway"

  name_prefix = "${var.project}-shared"
  tags        = local.common_tags

  vpc_attachments = [
    {
      name           = "shared"
      vpc_id         = module.shared_vpc.vpc_id
      subnet_ids     = module.shared_vpc.private_subnet_ids
      vpc_cidr       = var.shared_vpc_cidr
      route_table_id = module.shared_vpc.private_route_table_id
    },
    # Dev and Test VPCs are attached in their own workspaces using
    # the transit_gateway_id output from this state via a data source.
    # See dev/ and test/ directories.
  ]
}

# ── S3 (shared bucket) ────────────────────────────────────────────────────────

module "s3" {
  source = "../modules/s3"

  bucket_name        = "${var.project}-shared-data-${var.aws_account_id}"
  versioning_enabled = true
  kms_key_arn        = ""
  allowed_vpce_ids = [
    module.shared_vpc.s3_vpce_id,
    var.dev_s3_vpce_id,
    var.test_s3_vpce_id,
  ]
  tags = local.common_tags
}

# ── DynamoDB ──────────────────────────────────────────────────────────────────

module "dynamodb" {
  source = "../modules/dynamodb"

  table_name = "${var.project}-shared-items"
  hash_key   = "pk"
  range_key  = "sk"
  attributes = [
    { name = "pk", type = "S" },
    { name = "sk", type = "S" },
  ]

  allowed_vpce_ids = [
    module.shared_vpc.dynamodb_vpce_id,
    var.dev_dynamodb_vpce_id,
    var.test_dynamodb_vpce_id,
  ]
  allowed_principal_arns = [module.lambda.role_arn]
  tags                   = local.common_tags
}

# ── Lambda ────────────────────────────────────────────────────────────────────

module "lambda" {
  source = "../modules/lambda"

  name_prefix = "${var.project}-shared"
  vpc_id      = module.shared_vpc.vpc_id
  subnet_ids  = module.shared_vpc.private_subnet_ids
  filename    = "${path.module}/../lambda/function.zip"

  dynamodb_table_arns = [module.dynamodb.table_arn]
  dynamodb_table_name = module.dynamodb.table_name
  s3_bucket_arns      = [module.s3.bucket_arn]
  s3_bucket_name      = module.s3.bucket_id
  environment         = "shared"
  tags                = local.common_tags
}

# ── Private API Gateway ───────────────────────────────────────────────────────
# The execute-api VPC endpoint is created inside the networking module.

module "api_gateway" {
  source = "../modules/api_gateway"

  name_prefix = "${var.project}-shared"

  # The execute-api interface endpoint created by the networking module
  vpc_endpoint_ids     = [module.shared_vpc.vpc_endpoint_sg_id]
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  stage_name           = "v1"
  tags                 = local.common_tags
}

# ── NLB ───────────────────────────────────────────────────────────────────────

module "nlb" {
  source = "../modules/nlb"

  name_prefix   = "${var.project}-shared"
  vpc_id        = module.shared_vpc.vpc_id
  subnet_ids    = module.shared_vpc.private_subnet_ids
  listener_port = 80
  target_port   = 80
  tags          = local.common_tags
}

# ── Nginx Proxy ───────────────────────────────────────────────────────────────

module "nginx_proxy" {
  source = "../modules/nginx_proxy"

  name_prefix       = "${var.project}-shared"
  vpc_id            = module.shared_vpc.vpc_id
  vpc_cidr          = var.shared_vpc_cidr
  subnet_ids        = module.shared_vpc.private_subnet_ids
  upstream_url      = module.api_gateway.invoke_url
  desired_capacity  = 2
  min_size          = 1
  max_size          = 4
  target_group_arns = [module.nlb.target_group_arn]
  tags              = local.common_tags
}
