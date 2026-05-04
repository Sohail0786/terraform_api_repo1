###############################################################################
# Module: lambda
# Purpose: Shared Lambda function running inside the shared-services VPC.
#          Reads/writes DynamoDB and S3 via Gateway VPC Endpoints (no internet).
###############################################################################

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

# ── Inline policy: VPC networking + DynamoDB + S3 ────────────────────────────

data "aws_iam_policy_document" "lambda_policy" {
  # VPC networking (ENI management)
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
    ]
    resources = ["*"]
  }

  # CloudWatch Logs
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  # DynamoDB access
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = var.dynamodb_table_arns
  }

  # S3 access
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = flatten([
      for arn in var.s3_bucket_arns : [arn, "${arn}/*"]
    ])
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.name_prefix}-lambda-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# ── Security Group ────────────────────────────────────────────────────────────

resource "aws_security_group" "lambda" {
  name        = "${var.name_prefix}-lambda-sg"
  description = "Lambda function security group"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound (to VPC endpoints)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-lambda-sg" })
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name_prefix}-function"
  retention_in_days = 14
  tags              = var.tags
}

# ── Lambda Function ───────────────────────────────────────────────────────────

resource "aws_lambda_function" "this" {
  function_name = "${var.name_prefix}-function"
  role          = aws_iam_role.this.arn
  runtime       = var.runtime
  handler       = var.handler
  filename      = var.filename
  timeout       = var.timeout
  memory_size   = var.memory_size

  source_code_hash = filebase64sha256(var.filename)

  environment {
    variables = merge(
      {
        DYNAMODB_TABLE = var.dynamodb_table_name
        S3_BUCKET      = var.s3_bucket_name
        ENVIRONMENT    = var.environment
      },
      var.extra_env_vars
    )
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  depends_on = [
    aws_iam_role_policy.this,
    aws_cloudwatch_log_group.this,
  ]

  tags = var.tags
}
