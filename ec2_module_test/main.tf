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


module "web_server" {
    source ="./http_server"
    instance_type="t3.micro"
}

output "public_dns" {
    value=module.web_server.public_dns
}