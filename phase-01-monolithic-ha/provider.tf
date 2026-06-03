terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-southeast-1" # Region Singapura

  default_tags {
    tags = {
      Project     = "DevSecOps-Portfolio"
      Environment = "Development"
      ManagedBy   = "Terraform"
    }
  }
}