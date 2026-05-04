variable "project" {
  type    = string
  default = "myapp"
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "state_bucket" {
  type        = string
  description = "S3 bucket holding remote state for all environments"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

variable "dev_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "dev_private_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}
