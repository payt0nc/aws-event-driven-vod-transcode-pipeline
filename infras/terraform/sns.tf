resource "aws_sns_topic" "pipeline_job_status" {
  name = var.sns_video_job_status
  tags = local.default_tags
}

resource "aws_sns_topic_policy" "sns_video_job_status" {
  arn = aws_sns_topic.pipeline_job_status.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "PublishVideoPipelineStatusToSns",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "states.amazonaws.com"
        },
        "Action" : [
          "SNS:Publish"
        ],
        "Resource" : "${aws_sns_topic.pipeline_job_status.arn}",
        "Condition" : {
          "ArnLike" : {
            "AWS:SourceArn" : [
              "${aws_sfn_state_machine.vod_encoding_mediaconvert_job.arn}",
            ]
          },
          "StringEquals" : {
            "AWS:SourceAccount" : "${var.aws_account_id}"
          }
        }
      }
    ]
  })
}
