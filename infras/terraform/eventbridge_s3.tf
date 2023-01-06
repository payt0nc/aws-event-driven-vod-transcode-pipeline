resource "aws_cloudwatch_event_rule" "video_origin_object_upload" {
  name        = "${var.project_prefix}-video-origin-uploaded"
  role_arn    = aws_iam_role.eventbridge_sfn_vod_pipeline.arn
  description = "Capture S3 Object Created"
  tags        = local.default_tags
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

resource "aws_cloudwatch_event_target" "video_encoding_pipeline" {
  depends_on = [
    aws_iam_role_policy_attachment.eventbridge_sfn_vod_pipeline_sfn_policy
  ]
  rule     = aws_cloudwatch_event_rule.video_origin_object_upload.name
  arn      = aws_sfn_state_machine.vod_encoding_mediaconvert_job.arn
  role_arn = aws_iam_role.eventbridge_sfn_vod_pipeline.arn
}
