# public access
output "app_url" {
  description = "CloudFront domain — share this one, not the ALB"
  value       = "https://${module.edge.cloudfront_domain}"
}

output "load_balancer_endpoint" {
  description = "ALB endpoint, internal use only"
  value = module.app.alb_dns_name
  sensitive = true
}

# data layer
output "database_endpoint" {
  description = "RDS endpoint"
  value = module.data.db_endpoint
  sensitive = true
}

# storage
output "assets_bucket_name" {
  description = "S3 bucket for static assets"
  value = module.assets.bucket_name
}

# networking
output "vpc_id" {
  description = "VPC ID"
  value = module.network.vpc_id
}
