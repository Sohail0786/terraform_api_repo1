###############################################################################
# Module: nginx_proxy
# Purpose: EC2 Auto Scaling Group running Nginx as a reverse proxy in the
#          shared-services VPC.  Receives traffic from the NLB and forwards to
#          the private API Gateway endpoint.
###############################################################################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── IAM for SSM (no SSH bastion needed) ──────────────────────────────────────

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nginx" {
  name               = "${var.name_prefix}-nginx-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.nginx.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nginx" {
  name = "${var.name_prefix}-nginx-profile"
  role = aws_iam_role.nginx.name
}

# ── Security Group ────────────────────────────────────────────────────────────

resource "aws_security_group" "nginx" {
  name        = "${var.name_prefix}-nginx-sg"
  description = "Nginx proxy security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from NLB / VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "HTTPS from NLB / VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-nginx-sg" })
}

# ── Launch Template ───────────────────────────────────────────────────────────

resource "aws_launch_template" "nginx" {
  name_prefix            = "${var.name_prefix}-nginx-lt-"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.nginx.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.nginx.name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(templatefile("${path.module}/nginx.conf.tpl", {
    upstream_url = var.upstream_url
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name_prefix}-nginx" })
  }

  tags = var.tags
}

# ── Auto Scaling Group ────────────────────────────────────────────────────────

resource "aws_autoscaling_group" "nginx" {
  name                = "${var.name_prefix}-nginx-asg"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns

  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 60

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(var.tags, { Name = "${var.name_prefix}-nginx" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
