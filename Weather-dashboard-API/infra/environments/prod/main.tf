provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/vpc"

  env                  = var.env
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
