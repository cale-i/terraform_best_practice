terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

variable "region" {
  default = "ap-northeast-1"
}

variable "prefix" {
  default = "example"
}

variable "domain" {
  default = "random-stat.work"
}
