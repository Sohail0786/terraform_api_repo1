variable "name_prefix" {
  type = string
}

variable "vpc_endpoint_ids" {
  type        = list(string)
  description = "VPC Endpoint IDs for the execute-api service"
}

variable "lambda_invoke_arn" {
  type        = string
  description = "Invoke ARN of the Lambda function"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function (for permission resource)"
}

variable "stage_name" {
  type    = string
  default = "v1"
}

variable "tags" {
  type    = map(string)
  default = {}
}
