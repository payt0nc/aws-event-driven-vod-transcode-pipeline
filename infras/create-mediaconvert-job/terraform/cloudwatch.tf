resource "aws_cloudwatch_log_group" "lambda_emc_create_job" {
  name              = "/aws/lambda/${var.project_prefix}-emc-create-job"
  tags              = local.default_tags
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_resume_sfn" {
  name              = "/aws/lambda/${var.project_prefix}-resume-sfn"
  tags              = local.default_tags
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "sfn_vod_encoding_mediaconvert_job" {
  name              = "/aws/sfn/sfn-vod-encoding-mediaconvert-job"
  tags              = local.default_tags
  retention_in_days = 14
}
