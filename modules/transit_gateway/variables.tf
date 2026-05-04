variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_attachments" {
  description = <<-EOT
    List of VPCs to attach to the Transit Gateway.
    Each object must have:
      name           - unique label
      vpc_id         - VPC ID
      subnet_ids     - list of subnet IDs (one per AZ)
      vpc_cidr       - VPC CIDR block
      route_table_id - private route table to inject TGW routes into
  EOT
  type = list(object({
    name           = string
    vpc_id         = string
    subnet_ids     = list(string)
    vpc_cidr       = string
    route_table_id = string
  }))
}
