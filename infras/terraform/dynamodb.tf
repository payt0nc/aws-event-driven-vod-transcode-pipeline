resource "aws_dynamodb_table" "sfn_token" {
  name         = var.dynamodb_sfn_token_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Name"
  tags = merge(local.default_tags, {
    "Name" : var.dynamodb_sfn_token_table_name
  })

  attribute {
    name = "Name"
    type = "S"
  }
}
