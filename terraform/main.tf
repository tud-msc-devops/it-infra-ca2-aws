terraform {
  required_version = ">= 1.0"
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

# Network Module
module "network" {
  source = "./modules/network"
  
  environment_name        = var.environment_name
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  availability_zones      = var.availability_zones
}

# Database Module
module "database" {
  source = "./modules/database"
  
  environment_name        = var.environment_name
  vpc_id                  = module.network.vpc_id
  private_subnet_ids      = module.network.private_subnet_ids
  
  db_instance_class             = var.db_instance_class
  db_name                       = var.db_name
  db_username                   = var.db_username
  db_password                   = var.db_password
  db_allocated_storage          = var.db_allocated_storage
  db_backup_retention_period    = var.db_backup_retention_period
  
  app_server_security_group_id  = module.application.app_server_security_group_id
}

# Application Module
module "application" {
  source = "./modules/application"
  
  environment_name            = var.environment_name
  vpc_id                      = module.network.vpc_id
  public_subnet_ids           = module.network.public_subnet_ids
  private_subnet_ids          = module.network.private_subnet_ids
  
  instance_type               = var.instance_type
  key_name                    = var.key_name
  min_size                    = var.min_size
  max_size                    = var.max_size
  desired_capacity            = var.desired_capacity
  health_check_grace_period   = var.health_check_grace_period
  
  db_security_group_id        = module.database.db_security_group_id
  db_endpoint                 = module.database.db_endpoint
  db_name                     = var.db_name
}