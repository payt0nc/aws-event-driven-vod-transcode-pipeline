resource "aws_s3_bucket" "video_origin" {
  bucket = var.s3_video_origin_bucket_name
  tags = merge(local.default_tags,
    {
      Name = var.s3_video_origin_bucket_name
  })
}

resource "aws_s3_bucket_acl" "video_origin_acl" {
  bucket = aws_s3_bucket.video_origin.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "video_origin_versioning" {
  bucket = aws_s3_bucket.video_origin.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_notification" "video_input" {
  bucket      = aws_s3_bucket.video_origin.id
  eventbridge = true
}

