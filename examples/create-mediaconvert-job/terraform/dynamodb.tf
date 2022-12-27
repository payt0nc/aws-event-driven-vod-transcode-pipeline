resource "aws_dynamodb_table" "video_encoding_status_tracking" {
  name         = "video_encoding_status_tracking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "emcJobID"
  range_key    = "emcProgress"
  tags         = local.default_tags

  attribute {
    name = "emcJobID"
    type = "S"
  }

  attribute {
    name = "emcProgress"
    type = "S"
  }
}
