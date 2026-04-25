terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

module "storage" {
  source = "./modules/storage"

  project_name        = var.project_name
  environment         = var.environment
  cloudfront_oac_id   = module.cdn.oac_id
}

module "database" {
  source = "./modules/database"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  app_sg_id           = module.compute.app_sg_id
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
}

module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_type      = var.instance_type
  key_name           = var.key_name
  s3_bucket_name     = module.storage.bucket_name
  db_endpoint        = module.database.db_endpoint
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  aws_region         = var.aws_region
}

module "cdn" {
  source = "./modules/cdn"

  project_name   = var.project_name
  environment    = var.environment
  s3_bucket_id   = module.storage.bucket_id
  s3_bucket_arn  = module.storage.bucket_arn
  alb_dns_name   = module.compute.alb_dns_name
}
