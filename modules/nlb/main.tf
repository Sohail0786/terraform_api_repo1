###############################################################################
# Module: nlb
# Purpose: Internal Network Load Balancer in the shared-services VPC.
#          Targets are the Nginx proxy EC2 instances.
###############################################################################

resource "aws_lb" "this" {
  name               = "${var.name_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-nlb" })
}

# ── Target Group ──────────────────────────────────────────────────────────────

resource "aws_lb_target_group" "this" {
  name        = "${var.name_prefix}-nlb-tg"
  port        = var.target_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-nlb-tg" })
}

# ── Listener ──────────────────────────────────────────────────────────────────

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# ── Register targets ──────────────────────────────────────────────────────────

resource "aws_lb_target_group_attachment" "this" {
  for_each = toset(var.target_instance_ids)

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = each.value
  port             = var.target_port
}

# ── VPC Endpoint Service (PrivateLink) ────────────────────────────────────────
# Exposes the NLB so dev/test VPCs can consume it via a VPC Endpoint.

resource "aws_vpc_endpoint_service" "this" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.this.arn]

  tags = merge(var.tags, { Name = "${var.name_prefix}-nlb-endpoint-svc" })
}
