locals {
  default_tags = {
    Environment = "Dev"
    Project     = "vod-encoding-pipeline"
  }
}

variable "aws_account_id" {
  type = number
}
