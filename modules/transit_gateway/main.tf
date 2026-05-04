###############################################################################
# Module: transit_gateway
# Purpose: Creates a shared Transit Gateway and attaches one or more VPCs to it.
#          Propagates routes so any attached VPC can route to every other.
###############################################################################

resource "aws_ec2_transit_gateway" "this" {
  description                     = "${var.name_prefix} Transit Gateway"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = merge(var.tags, { Name = "${var.name_prefix}-tgw" })
}

# ── Attachments ───────────────────────────────────────────────────────────────
# One attachment per VPC passed in.  Each entry in var.vpc_attachments must
# supply { vpc_id, subnet_ids, vpc_cidr }.

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = { for a in var.vpc_attachments : a.name => a }

  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = each.value.vpc_id
  subnet_ids         = each.value.subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-tgw-attach-${each.key}" })
}

# ── Routes back to each remote VPC ────────────────────────────────────────────
# For every attachment that has a route_table_id, add a route pointing to TGW
# for all *other* VPC CIDRs.

locals {
  # Flatten: for each attachment's route table, add a route for every OTHER cidr
  cross_routes = flatten([
    for src in var.vpc_attachments : [
      for dst in var.vpc_attachments : {
        key            = "${src.name}-to-${dst.name}"
        route_table_id = src.route_table_id
        cidr           = dst.vpc_cidr
        attachment_key = dst.name
      }
      if src.name != dst.name
    ]
  ])
}

resource "aws_route" "tgw" {
  for_each = { for r in local.cross_routes : r.key => r }

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.cidr
  transit_gateway_id     = aws_ec2_transit_gateway.this.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}
