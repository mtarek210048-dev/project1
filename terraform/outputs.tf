output "cloudfront_url" {
  description = "CloudFront distribution URL — use this to access the app"
  value       = "https://${module.cdn.cloudfront_domain}"
}

output "alb_dns_name" {
  description = "ALB DNS name (direct access, bypasses CloudFront)"
  value       = module.compute.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint (private — accessible only from within VPC)"
  value       = module.database.db_endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket name for static assets"
  value       = module.storage.bucket_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
