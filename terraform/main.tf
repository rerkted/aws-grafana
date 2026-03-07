# ─── main.tf ───────────────────────────────────────────────────
# Observability stack — dedicated Grafana EC2
# Separate from portfolio EC2 for independent lifecycle

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "rerkt-terraform-state"
    key    = "grafana/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "grafana"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}

## ─── DATA SOURCES ─────────────────────────────────────────────

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_availability_zones" "available" {}

data "aws_route53_zone" "domain" {
  name         = "rerktserver.com"
  private_zone = false
}
