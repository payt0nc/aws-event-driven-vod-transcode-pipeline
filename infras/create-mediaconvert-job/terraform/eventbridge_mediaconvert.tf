resource "aws_cloudwatch_event_rule" "emc_job_status_change" {
  name        = "${var.project_prefix}-emc-job-status-change"
  role_arn    = aws_iam_role.eventbridge_sfn_video_pipeline.arn
  description = "Capture MediaCovert Status Change"
  event_pattern = jsonencode({
    "source" : ["aws.mediaconvert"],
    "detail-type" : ["MediaConvert Job State Change"],
    "detail" : {
      "status" : ["ERROR", "COMPLETE"]
    }
  })
}

resource "aws_cloudwatch_event_target" "mediaconvert_log_group" {
  rule = aws_cloudwatch_event_rule.emc_job_status_change.name
  arn  = aws_cloudwatch_log_group.mediaconvert_events.arn
}

resource "aws_cloudwatch_event_target" "video_encoding_pipeline_sfn_callback" {
  rule = aws_cloudwatch_event_rule.emc_job_status_change.name
  arn  = aws_lambda_function.callback_create_emc_job.arn

  input_transformer {
    input_paths = {
      jobId        = "$.detail.jobId"
      status       = "$.detail.status"
      userMetadata = "$.detail.userMetadata"
    }

    input_template = <<EOF
{
  "jobId": <jobId>,
  "status": <status>,
  "userMetadata": <userMetadata>
}
EOF
  }
}


resource "aws_iam_role" "eventbridge_sfn_video_pipeline" {
  name_prefix = "eventbridge-sfn-video-pipeline-"
  tags        = local.default_tags
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "events.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_sfn_video_pipeline" {
  name_prefix = "eventbridge-sfn-video-pipeline-"
  tags        = local.default_tags
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "states:StartExecution"
        ],
        "Resource" : [
          "${aws_sfn_state_machine.vod_encoding_mediaconvert_job.arn}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        "Resource" : [
          "${aws_cloudwatch_log_group.mediaconvert_events.arn}:*",
          "${aws_cloudwatch_log_group.mediapackage_events.arn}:*",
          "${aws_cloudwatch_log_group.sfn_vod_encoding_mediaconvert_job.arn}:*",
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction"
        ],
        "Resource" : [
          "${aws_lambda_function.callback_create_emc_job.arn}:*"
        ],
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_sfn_video_pipeline_sfn_policy" {
  role       = aws_iam_role.eventbridge_sfn_video_pipeline.name
  policy_arn = aws_iam_policy.eventbridge_sfn_video_pipeline.arn
}
