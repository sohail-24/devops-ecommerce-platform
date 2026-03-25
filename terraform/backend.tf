terraform {
  backend "s3" {
    bucket         = "sohail-terraform-state-2026-001"
    key            = "ecommerce/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
