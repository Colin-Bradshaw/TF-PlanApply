terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "tf-utopia-state"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"
  }
}

provider "aws" {
  region = "us-east-2"
}
