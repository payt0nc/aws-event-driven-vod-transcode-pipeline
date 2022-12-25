resource "aws_s3_bucket" "video_origin" {
  bucket = "hpchan-poc-video-origin"

  tags = merge(local.default_tags,
    {
      Name = "hpchan-poc-video-origin"
  })
}

resource "aws_s3_bucket_acl" "poc_video_origin_acl" {
  bucket = aws_s3_bucket.video_origin.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "poc_video_origin_versioning" {
  bucket = aws_s3_bucket.video_origin.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "video_encoding_sns" {
  bucket      = aws_s3_bucket.video_origin.id
  eventbridge = true
  topic {
    id            = "video-pipeline-s3-notification"
    topic_arn     = aws_sns_topic.video_pipeline_origin_upload_events.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "video-origin-"
  }
}


resource "aws_s3_bucket" "video_output" {
  bucket = "hpchan-poc-video-output"

  tags = merge(local.default_tags,
    {
      Name = "hpchan-poc-video-output"
  })
}

resource "aws_s3_bucket_acl" "poc_video_output_acl" {
  bucket = aws_s3_bucket.video_output.id
  acl    = "private"
}
