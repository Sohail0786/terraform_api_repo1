variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for the NLB (one per AZ)"
}

variable "listener_port" {
  type        = number
  default     = 80
  description = "Port the NLB listener accepts traffic on"
}

variable "target_port" {
  type        = number
  default     = 80
  description = "Port on the target instances"
}

variable "target_instance_ids" {
  type        = list(string)
  description = "EC2 instance IDs to register in the target group"
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
