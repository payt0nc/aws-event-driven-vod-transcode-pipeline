resource "aws_sns_topic" "video_pipeline_encoding_result" {
  name = "video-pipeline-encoding-results"
  tags = local.default_tags
}

resource "aws_sns_topic" "video_pipeline_origin_upload_events" {
  name = "video-pipeline-origin-upload-events"
  tags = local.default_tags
}

resource "aws_sns_topic_policy" "video_origin_uploaded_policy" {
  arn = aws_sns_topic.video_pipeline_origin_upload_events.arn
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
        "Resource" : "${aws_sns_topic.video_pipeline_origin_upload_events.arn}",
        "Condition" : {
          "ArnLike" : {
            "AWS:SourceArn" : "${aws_s3_bucket.video_origin.arn}"
          },
          "StringEquals" : {
            "AWS:SourceAccount" : "${var.aws_account_id}"
          }
        }
      },
      {
        "Sid" : "PublishVideoOriginEventFromStepFunctionToSns",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "states.amazonaws.com"
        },
        "Action" : [
          "SNS:Publish"
        ],
        "Resource" : "${aws_sns_topic.video_pipeline_origin_upload_events.arn}",
        "Condition" : {
          "ArnLike" : {
            "AWS:SourceArn" : "arn:aws:states:ap-northeast-1:${var.aws_account_id}:stateMachine:EMC-Encoding-Pipeline"
          },
          "StringEquals" : {
            "AWS:SourceAccount" : "${var.aws_account_id}"
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue" "video_pipeline_deadletter_queue" {
  name                      = "video-pipeline-deadletter-queue"
  delay_seconds             = 5
  max_message_size          = 4096
  message_retention_seconds = 6400
  receive_wait_time_seconds = 10
  tags                      = local.default_tags
}

resource "aws_sqs_queue" "video_pipeline_job_queue" {
  name                      = "video-pipeline-job-queue"
  delay_seconds             = 5
  max_message_size          = 4096
  message_retention_seconds = 6400
  receive_wait_time_seconds = 10
  tags                      = local.default_tags
}
