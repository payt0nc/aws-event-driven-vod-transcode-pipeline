resource "aws_media_convert_queue" "vod_pipeline" {
  name = var.project_prefix
  tags = local.default_tags
}


resource "aws_iam_role" "mediaconvert_execution" {
  name = "${var.project_prefix}-mediaconvert-execution"
  tags = local.default_tags
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "mediaconvert.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

}

resource "aws_iam_policy" "mediaconvert_execution_access_s3_buckets" {
  name = "${var.project_prefix}-mediaconvert-execution-s3-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "mediaconvert:*",
          "s3:ListAllMyBuckets",
          "s3:ListBucket"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*"
        ],
        "Resource" : [
          "${aws_s3_bucket.video_origin.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Put*"
        ],
        "Resource" : [
          "${aws_s3_bucket.video_output.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mediaconvert" {
  role       = aws_iam_role.mediaconvert_execution.name
  policy_arn = aws_iam_policy.mediaconvert_execution_access_s3_buckets.arn
}
