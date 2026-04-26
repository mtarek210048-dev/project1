# --- global
variable "aws_region" {
  description = "region to deploy into, e.g. eu-north-1"
  type        = string
  validation {
    condition = length(var.aws_region) > 0
    error_message = "region can't be empty."
  }
}

variable "environment" {
  description = "dev, staging, or prod"
  type = string
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "used as a prefix for all resource names"
  type = string
}

# networking
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

# compute
variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair for SSH — leave empty if not needed"
  type = string
  default = ""
}

variable "min_size" {
  type = number
  default = 1
}

variable "max_size" {
  type = number
  default = 4
}

# --- database
variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

# no db_password — generated internally by the data module

# --- security + edge
variable "waf_enabled" {
  type = bool
  default = true
}

variable "allowed_origins" {
  type = list(string)
  default = []
}

# monitoring
variable "alarm_email" {
  description = "gets paged when alarms fire"
  type = string
}
