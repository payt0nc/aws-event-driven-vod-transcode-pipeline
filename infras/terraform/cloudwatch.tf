resource "aws_cloudwatch_log_group" "lambda_create_encoding_job" {
  name              = "/aws/lambda/${var.project_prefix}-create-encoding-job"
  tags              = local.default_tags
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_callback_create_encoding_job" {
  name              = "/aws/lambda/${var.project_prefix}-callback-create-encoding-job"
  tags              = local.default_tags
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "sfn_vod_pipeline_job" {
  name              = "/aws/sfn/${var.project_prefix}/sfn-vod-pipeline-job"
  tags              = local.default_tags
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "mediaconvert_events" {
  name              = "/aws/mediaconvert/${var.project_prefix}"
  tags              = local.default_tags
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "mediapackage_events" {
  name              = "/aws/mediapackage/${var.project_prefix}"
  tags              = local.default_tags
  retention_in_days = 14
}
