terraform {
  backend "s3" {
    bucket         = "weather-app-backend-terraform-bucket-2025"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}

