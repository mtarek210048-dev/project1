variable "project_name"       { type = string }
variable "environment"        { type = string }
variable "vpc_id"             { type = string }
variable "public_subnet_ids"  { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "instance_type"      { type = string }
variable "key_name"           { type = string }
variable "s3_bucket_name"     { type = string }
variable "db_endpoint"        { type = string }
variable "db_name"            { type = string }
variable "db_username"        { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "aws_region"         { type = string }
