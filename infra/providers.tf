terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend parcial: bucket, key, região e tabela vêm de backend.hcl (gerado por
  # backend/bootstrap.sh). Uso: terraform init -backend-config=backend.hcl
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}
