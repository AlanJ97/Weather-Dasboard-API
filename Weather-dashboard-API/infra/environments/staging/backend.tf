terraform {
  backend "s3" {
    bucket = "weather-app-backend-terraform-bucket-2025"
    key    = "staging/terraform.tfstate"
    region = "us-east-1"
  }
}
