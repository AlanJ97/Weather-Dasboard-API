terraform {
  backend "s3" {
    bucket  = "weather-app-backend-terraform-bucket-2025-ohio"
    key     = "dev/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

