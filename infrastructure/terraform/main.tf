# BB_SDK AWS Infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource tagging"
  default     = "bb-sdk"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "your_ip" {
  description = "Your IP address for SSH access"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for ALB"
  type        = string
}
