output "cloudfront_url" {
  value       = "https://${module.cdn.cloudfront_domain}"
}

output "alb_dns_name" {
  value       = module.compute.alb_dns_name
}

output "rds_endpoint" {
  value       = module.database.db_endpoint
}

output "s3_bucket_name" {
  value       = module.storage.bucket_name
}

output "vpc_id" {
  value       = module.vpc.vpc_id
}
