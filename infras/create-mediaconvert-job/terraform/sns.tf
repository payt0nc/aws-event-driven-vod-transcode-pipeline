resource "aws_sns_topic" "s3_event" {
  name = var.video_s3_event_topic
  tags = local.default_tags
}

resource "aws_sns_topic_policy" "s3_event_policy" {
  arn = aws_sns_topic.s3_event.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "PublishVideoOriginEventFromS3ToSns",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "s3.amazonaws.com"
        },
        "Action" : [
          "SNS:Publish"
        ],
        "Resource" : "${aws_sns_topic.s3_event.arn}",
        "Condition" : {
          "ArnLike" : {
            "AWS:SourceArn" : [
              "${aws_s3_bucket.video_origin.arn}",
              "${aws_s3_bucket.video_output.arn}",
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

resource "aws_sns_topic" "pipeline_job_status" {
  name = var.sns_video_job_status
  tags = local.default_tags
}

resource "aws_sns_topic_policy" "sns_video_job_status" {
  arn = aws_sns_topic.s3_event.arn
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
