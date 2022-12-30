// Start job
resource "aws_cloudwatch_event_rule" "emc_job_status_change" {
  name     = "${var.project_prefix}-emc-job-status-change"
  role_arn = aws_iam_role.eventbridge_sfn_video_pipeline.arn
  # description = "Capture all EC2 scaling events"
  event_pattern = jsonencode({
    "source" : ["aws.mediaconvert"],
    "detail-type" : ["MediaConvert Job State Change"],
    "detail" : {
      "status" : ["ERROR", "COMPLETE"]
    }
  })
}

resource "aws_cloudwatch_event_target" "video_encoding_pipeline" {
  depends_on = [
    aws_iam_role_policy_attachment.eventbridge_sfn_video_pipeline_sfn_policy
  ]
  rule     = aws_cloudwatch_event_rule.video_origin_object_upload.name
  arn      = aws_sfn_state_machine.vod_encoding_mediaconvert_job.arn
  role_arn = aws_iam_role.eventbridge_sfn_video_pipeline.arn
}

// Complete Job
resource "aws_cloudwatch_event_rule" "video_origin_object_upload" {
  name     = "${var.project_prefix}-video-origin-uploaded"
  role_arn = aws_iam_role.eventbridge_sfn_video_pipeline.arn
  # description = "Capture all EC2 scaling events"
  event_pattern = jsonencode({
    "source" : [
      "aws.s3"
    ],
    "detail-type" : [
      "Object Created"
    ],
    "detail" : {
      "bucket" : {
        "name" : [
          aws_s3_bucket.video_origin.id
        ]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "video_encoding_pipeline_sfn_callback" {
  rule = aws_cloudwatch_event_rule.emc_job_status_change.name
  arn  = aws_lambda_function.resume_sfn.arn

  input_transformer {
    input_paths = {
      jobId  = "$.detail.jobId"
      status = "$.detail.status"
    }

    input_template = <<EOF
{
  "jobId": <jobId>,
  "status": <status>
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
          "lambda:InvokeFunction"
        ],
        "Resource" : [
          "${aws_lambda_function.resume_sfn.arn}:*"
        ],
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_sfn_video_pipeline_sfn_policy" {
  role       = aws_iam_role.eventbridge_sfn_video_pipeline.name
  policy_arn = aws_iam_policy.eventbridge_sfn_video_pipeline.arn
}
