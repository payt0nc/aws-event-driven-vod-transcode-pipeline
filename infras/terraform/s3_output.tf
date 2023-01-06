resource "aws_s3_bucket" "video_output" {
  bucket = var.s3_video_output_bucket_name
  tags = merge(local.default_tags,
    {
      Name = var.s3_video_output_bucket_name
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
