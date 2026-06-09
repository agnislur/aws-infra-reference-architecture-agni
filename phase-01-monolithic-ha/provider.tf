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
  region = "ap-southeast-3"

  default_tags {
    tags = {
      Project     = "DevSecOps-Masterpiece"
      Phase       = "01-Monolithic-HA"
      ManagedBy   = "Terraform"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "agni-tf-remote-state-bucket-yosh123" # Samakan dengan nama bucket di Langkah 2
    key            = "phase-01/terraform.tfstate"      # Path state file di dalam S3
    region         = "ap-southeast-3"
    dynamodb_table = "agni-tf-state-locks"
    encrypt        = true
  }
}