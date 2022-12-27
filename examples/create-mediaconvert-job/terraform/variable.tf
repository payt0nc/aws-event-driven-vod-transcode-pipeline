locals {
  default_tags = {
    Environment = "Dev"
    Project     = "vod-encoding-pipeline"
  }
}

variable "aws_account_id" {
  type = number
}

variable "aws_tfstate_bucket" {
  type = string
}

variable "aws_tfstate_key" {
  type = string
}

variable "aws_default_region" {
  type = string
}
