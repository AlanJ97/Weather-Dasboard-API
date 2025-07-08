terraform {
  backend "s3" {
    bucket = "weather-app-backend-terraform-bucket-2025"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
