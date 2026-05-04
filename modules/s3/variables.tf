variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name"
}

variable "versioning_enabled" {
  type    = bool
  default = true
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for server-side encryption (leave empty for aws/s3 managed key)"
  default     = ""
}

variable "allowed_vpce_ids" {
  type        = list(string)
  description = "S3 Gateway VPC Endpoint IDs allowed to access this bucket"
}

variable "tags" {
  type    = map(string)
  default = {}
}
