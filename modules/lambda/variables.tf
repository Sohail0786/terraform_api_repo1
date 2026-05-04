variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets for Lambda VPC attachment"
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "handler" {
  type    = string
  default = "handler.lambda_handler"
}

variable "filename" {
  type        = string
  description = "Path to the deployment zip file"
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memory_size" {
  type    = number
  default = 256
}

variable "dynamodb_table_arns" {
  type        = list(string)
  description = "ARNs of DynamoDB tables the function may access"
  default     = []
}

variable "dynamodb_table_name" {
  type    = string
  default = ""
}

variable "s3_bucket_arns" {
  type        = list(string)
  description = "ARNs of S3 buckets the function may access"
  default     = []
}

variable "s3_bucket_name" {
  type    = string
  default = ""
}

variable "environment" {
  type    = string
  default = "shared"
}

variable "extra_env_vars" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
