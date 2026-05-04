variable "table_name" {
  type = string
}

variable "hash_key" {
  type    = string
  default = "pk"
}

variable "range_key" {
  type    = string
  default = ""
}

variable "attributes" {
  description = "List of attribute definitions {name, type}"
  type = list(object({
    name = string
    type = string # S | N | B
  }))
  default = [
    { name = "pk", type = "S" },
    { name = "sk", type = "S" },
  ]
}

variable "global_secondary_indexes" {
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string)
    projection_type = string
  }))
  default = []
}

variable "allowed_vpce_ids" {
  type        = list(string)
  description = "DynamoDB Gateway VPC Endpoint IDs allowed to access this table"
}

variable "allowed_principal_arns" {
  type        = list(string)
  description = "IAM role/user ARNs permitted by the resource policy"
}

variable "tags" {
  type    = map(string)
  default = {}
}
