resource "aws_dynamodb_table" "video_job_progress" {
  name         = var.video_job_progress_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "emcJobId"
  tags = merge(local.default_tags, {
    "Name" : var.video_job_progress_table_name
  })

  attribute {
    name = "emcJobId"
    type = "S"
  }
}
