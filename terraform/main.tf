terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "your-tfstate-bucket"
    key            = "project1/dev/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }

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

# --- networking layer
module "network" {
  source = "./modules/network"

  name_prefix        = "${var.project_name}-${var.environment}"
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# --- data + storage layer
module "data" {
  source = "./modules/data"

  name_prefix = "${var.project_name}-${var.environment}"
  vpc_id      = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  app_sg_id   = module.app.app_sg_id
  db_name     = var.db_name
  db_username = var.db_username
}

module "assets" {
  source = "./modules/assets"

  name_prefix     = "${var.project_name}-${var.environment}"
  environment     = var.environment
  allowed_origins = var.allowed_origins
}

module "edge" {
  source = "./modules/edge"

  name_prefix = "${var.project_name}-${var.environment}"
  bucket_id   = module.assets.bucket_id
  bucket_arn  = module.assets.bucket_arn
  waf_enabled     = var.waf_enabled
  allowed_origins = var.allowed_origins
}

# --- application layer
module "app" {
  source = "./modules/app"

  name_prefix = "${var.project_name}-${var.environment}"
  vpc_id      = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  instance_type = var.instance_type
  key_name      = var.key_name
  min_size = var.min_size
  max_size = var.max_size
  db_endpoint   = module.data.db_endpoint
  db_name       = var.db_name
  db_username   = var.db_username
  db_secret_arn = module.data.db_secret_arn
  bucket_name   = module.assets.bucket_name
}

# --- edge wiring (cdn <-> alb)
module "edge_integration" {
  source = "./modules/edge_integration"

  name_prefix  = "${var.project_name}-${var.environment}"
  alb_dns_name = module.app.alb_dns_name
  oac_id       = module.edge.oac_id
}

# alerts for asg, rds and alb — tweak thresholds in the module if needed
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix    = "${var.project_name}-${var.environment}"
  asg_name       = module.app.asg_name
  db_identifier  = module.data.db_identifier
  alb_arn_suffix = module.app.alb_arn_suffix
  alarm_email    = var.alarm_email
}
