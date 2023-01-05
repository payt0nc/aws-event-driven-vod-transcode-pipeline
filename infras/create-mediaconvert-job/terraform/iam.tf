resource "aws_iam_role" "mediapackage_segmentor" {
  name = "mediapackage_segmentor"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "mediapackage.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

}

resource "aws_iam_policy" "mediapackage_access_s3" {
  name_prefix = "mediapackage_segmentor"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:GetBucketRequestPayment",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.video_output.arn}/*",
          "${aws_s3_bucket.video_output.arn}",
        ],
        "Effect" : "Allow"
      }
    ]
  })

}


resource "aws_iam_role_policy_attachment" "add_policy" {
  role       = aws_iam_role.mediapackage_segmentor.name
  policy_arn = aws_iam_policy.mediapackage_access_s3.arn
}
