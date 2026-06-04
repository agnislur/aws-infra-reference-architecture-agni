terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.48"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-southeast-1"

  default_tags {
    tags = {
      Project     = "DevSecOps-Masterpiece"
      Phase       = "01-Monolithic-HA"
      ManagedBy   = "Terraform"
    }
  }
}