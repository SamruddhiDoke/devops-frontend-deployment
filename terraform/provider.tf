terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State is stored locally in terraform/terraform.tfstate (git-ignored).
  # Keep it safe: losing it means Terraform can no longer manage these resources.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "taskflow"
      ManagedBy = "terraform"
    }
  }
}
