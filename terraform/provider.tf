terraform {
  backend "s3" {
    bucket = "shopnow-terraform-state-2026"
    key    = "shopnow/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = "ap-south-1"
}
