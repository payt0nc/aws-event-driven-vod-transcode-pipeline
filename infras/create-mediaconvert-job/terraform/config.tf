terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.48"
    }
  }
  backend "s3" {
    bucket = "hpchan-infrastruture"
    key    = "solutions/aws-event-driven-vod-transcode-pipeline/dev.tfstate"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  region = var.aws_region
}
