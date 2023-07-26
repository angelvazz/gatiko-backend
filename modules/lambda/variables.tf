variable "name" {
  type = string
}

variable "bucket_id" {
  type = string
}

variable "user_pool_id" {
  description = "Cognito pool id"
  type = string
  default = null
}

variable "table_arn_dynamodb" {
  description = "DynamoDB table ARN"
  type = string
  default = ""
}