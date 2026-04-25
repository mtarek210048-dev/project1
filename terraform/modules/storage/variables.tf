variable "project_name"      { type = string }
variable "environment"       { type = string }
variable "cloudfront_oac_id" { type = string }

terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
