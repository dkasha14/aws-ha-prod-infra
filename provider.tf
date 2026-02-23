provider "aws" {
  region = var.dk_aws_region
}

terraform {
  backend "s3" {
    bucket         = "dk-tf-state-bucket-ha-prod" 
    key            = "ha-production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dk-tf-state-lock-table"
    encrypt        = true
  }
}
