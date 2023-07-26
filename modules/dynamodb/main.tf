resource "aws_dynamodb_table" "gatiko-table" {
  name           = "gatiko-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
