terraform {
  required_version = ">= 1.1.7"
  required_providers {
    aws = {
      version = ">= 4.11.0, < 5.0.0"
      source = "hashicorp/aws"
    }
  }
    backend "s3" {
    bucket = "terraform-s3-backend-with-locking-magzim"
    key    = "magz8s"
    region = "us-west-1"
  }

}

provider "aws" {
  region = "ca-central-1"
  sts_region = "ca-central-1"

  default_tags {
    tags = var.tags
  }
}
