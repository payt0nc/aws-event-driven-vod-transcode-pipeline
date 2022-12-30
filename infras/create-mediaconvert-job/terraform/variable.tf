locals {
  default_tags = {
    Environment = var.project_env
    Project     = var.project_prefix
  }
  iam_naming_prefix = var.project_prefix
}

variable "aws_account_id" {
  type = number
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "aws_tfstate_bucket" {
  type = string
}

variable "aws_tfstate_key" {
  type = string
}

variable "project_env" {
  type = string
}

variable "project_prefix" {
  type        = string
  description = "vod-encoding-pipeline"
}


variable "video_origin_bucket_name" {
  type    = string
  default = "vod-encoding-pipeline-video-origin"
}

variable "video_output_bucket_name" {
  type    = string
  default = "vod-encoding-pipeline-video-output"
}

variable "video_origin_filename_prefix" {
  type    = string
  default = "video-origin-"
}

variable "video_output_filename_prefix" {
  type    = string
  default = "video-output-"
}

variable "video_s3_event_topic" {
  type    = string
  default = "vod-encoding-pipeline-s3-object-event"
}

variable "video_job_progress_table_name" {
  type    = string
  default = "vod-encoding-pipeline-job-progress"
}


variable "lambda_fucntion_s3_bucket" {
  type = string
}

variable "lambda_fucntion_s3_create_emc_job_runtime" {
  type = string
}

variable "lambda_fucntion_s3_resume_sfn_runtime" {
  type = string
}

variable "lambda_fucntion_s3_slack_messager_runtime" {
  type = string
}


variable "mediaconvert_endpoint" {
  type = string
}


variable "sns_video_job_status" {
  type = string
}
