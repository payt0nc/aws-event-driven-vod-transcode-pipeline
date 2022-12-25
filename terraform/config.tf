terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.48"
    }
  }
  backend "s3" {
    bucket = var.aws_tfstate_bucket
    key    = var.aws_tfstate_key
    region = var.aws_default_region
  }
}

provider "aws" {
  region = var.aws_default_region
}
