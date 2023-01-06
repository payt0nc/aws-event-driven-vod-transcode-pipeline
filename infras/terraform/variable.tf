locals {
  default_tags = {
    Environment = var.project_env
    Project     = var.project_prefix
  }
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


###


variable "eventbridge_bus_name" {
  type = string
}

variable "dynamodb_sfn_token_table_name" {
  type = string
}

variable "lambda_fucntion_s3_bucket" {
  type = string
}

variable "lambda_fucntion_s3_create_encoding_job_runtime" {
  type = string
}

variable "lambda_fucntion_s3_callback_create_encoding_job_runtime" {
  type = string
}

variable "mediaconvert_endpoint" {
  type = string
}

variable "mediapackage_packing_group_id" {
  type = string
}

variable "s3_video_origin_bucket_name" {
  type    = string
  default = "vod-encoding-pipeline-video-origin"
}

variable "s3_video_output_bucket_name" {
  type    = string
  default = "vod-encoding-pipeline-video-output"
}

variable "sns_video_job_status" {
  type = string
}
