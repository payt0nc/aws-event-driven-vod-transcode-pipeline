resource "aws_cloudwatch_log_group" "lambda_emc_create_job" {
  name              = "/aws/lambda/${var.project_prefix}-emc-create-job"
  tags              = local.default_tags
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_callback_create_emc_job" {
  name              = "/aws/lambda/${var.project_prefix}-callback-create-emc-job"
  tags              = local.default_tags
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "sfn_vod_encoding_mediaconvert_job" {
  name              = "/aws/sfn/sfn-vod-encoding-mediaconvert-job"
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

