variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets for the ASG"
}

variable "upstream_url" {
  type        = string
  description = "URL of the upstream service Nginx proxies to (e.g. private API Gateway URL)"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 4
}

variable "target_group_arns" {
  type        = list(string)
  description = "NLB target group ARNs to attach the ASG to"
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
