terraform {
  required_version = ">= 1.1.7"
  required_providers {
    aws = {
      version = ">= 4.11.0, < 5.0.0"
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "terraform-s3-backend-with-locking-magzim"
    key    = "magz8s"
    region = "us-west-1" # change to ca-central-1
  }

}

provider "aws" {
  region     = "ca-central-1"
  sts_region = "ca-central-1"

  default_tags {
    tags = var.tags
  }
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
  }
}