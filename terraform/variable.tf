locals {
  default_tags = {
    Environment = "Dev"
    Project     = "vod-encoding-pipeline"
  }
}

variable "aws_account_id" {
  type = number
}

varible "aws_tfstate_bucket" {
  type = string
}

varible "aws_tfstate_key" {
  type = string
}

varible "aws_default_region" {
  type = string
}
