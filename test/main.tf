###############################################################################
# Test environment – root configuration
# Mirror of dev/main.tf with test-specific CIDR ranges.
###############################################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  # backend "s3" {
  #   bucket         = "my-tf-state-bucket"
  #   key            = "test/terraform.tfstate"
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
    Environment = "test"
    ManagedBy   = "terraform"
  }
}

# ── Read shared state ─────────────────────────────────────────────────────────

data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "shared/terraform.tfstate"
    region = var.aws_region
  }
}

# ── Test VPC ──────────────────────────────────────────────────────────────────

module "test_vpc" {
  source = "../modules/networking"

  name_prefix          = "${var.project}-test"
  vpc_cidr             = var.test_vpc_cidr
  private_subnet_cidrs = var.test_private_subnet_cidrs
  availability_zones   = var.availability_zones
  aws_region           = var.aws_region
  tags                 = local.common_tags
}

# ── Attach Test VPC to the shared Transit Gateway ─────────────────────────────

resource "aws_ec2_transit_gateway_vpc_attachment" "test" {
  transit_gateway_id = data.terraform_remote_state.shared.outputs.transit_gateway_id
  vpc_id             = module.test_vpc.vpc_id
  subnet_ids         = module.test_vpc.private_subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = merge(local.common_tags, { Name = "${var.project}-test-tgw-attach" })
}

resource "aws_route" "to_shared" {
  route_table_id         = module.test_vpc.private_route_table_id
  destination_cidr_block = data.terraform_remote_state.shared.outputs.shared_vpc_cidr
  transit_gateway_id     = data.terraform_remote_state.shared.outputs.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.test]
}

# ── VPC Endpoint to reach the shared NLB via PrivateLink ──────────────────────

resource "aws_vpc_endpoint" "shared_nlb" {
  vpc_id              = module.test_vpc.vpc_id
  service_name        = data.terraform_remote_state.shared.outputs.nlb_endpoint_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.test_vpc.private_subnet_ids
  security_group_ids  = [module.test_vpc.vpc_endpoint_sg_id]
  private_dns_enabled = false

  tags = merge(local.common_tags, { Name = "${var.project}-test-shared-nlb-vpce" })
}
