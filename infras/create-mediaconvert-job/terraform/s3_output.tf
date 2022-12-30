resource "aws_s3_bucket" "video_output" {
  bucket = var.video_output_bucket_name

  tags = merge(local.default_tags,
    {
      Name = var.video_output_bucket_name
  })
}

resource "aws_s3_bucket_acl" "video_output_acl" {
  bucket = aws_s3_bucket.video_output.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "video_output_versioning" {
  bucket = aws_s3_bucket.video_output.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "video_output" {
  bucket      = aws_s3_bucket.video_output.id
  eventbridge = true
  topic {
    id            = "video-pipeline-s3-notification"
    topic_arn     = aws_sns_topic.s3_event.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.video_output_filename_prefix
  }
}

