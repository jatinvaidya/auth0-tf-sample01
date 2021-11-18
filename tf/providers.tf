terraform {
  required_version = ">= 0.14"
  required_providers {
    auth0 = {
      source  = "alexkappa/auth0"
      version = "~> 0.24"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.35"
    }
  }
}

provider "auth0" {
  domain        = var.auth0_domain
  client_id     = var.auth0_tf_client_id
  client_secret = var.auth0_tf_client_secret
  debug         = "true"
}

provider "aws" {
  profile = "terraform-cli"
  region  = var.aws_region
}
