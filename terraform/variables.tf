############################
# Global Configuration
############################
variable "region" {
  description = "AWS region for deployment"
  type        = string

  validation {
    condition     = length(var.region) > 0
    error_message = "Region must not be empty."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project" {
  description = "Project identifier used in naming"
  type        = string
}

############################
# Networking
############################
variable "network_config" {
  description = "Networking configuration for VPC and subnets"
  type = object({
    vpc_cidr           = string
    availability_zones = list(string)
    public_subnets     = list(string)
    private_subnets    = list(string)
  })
}

############################
# Compute
############################
variable "app_config" {
  description = "Application compute configuration"
  type = object({
    instance_type = string
    key_name      = optional(string)
  })

  default = {
    instance_type = "t3.micro"
  }
}

############################
# Database
############################
variable "database_config" {
  description = "Database configuration"
  type = object({
    name     = string
    username = string
    password = string
  })

  sensitive = true
}
