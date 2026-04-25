#################################
# Edge / Public Access
#################################
output "app_url" {
  description = "Public URL of the application via CDN"
  value       = "https://${module.edge.cloudfront_domain}"
}

output "load_balancer_endpoint" {
  description = "Direct ALB endpoint (internal use / debugging)"
  value       = module.app.alb_dns_name
}

#################################
# Data Layer
#################################
output "database_endpoint" {
  description = "Primary database connection endpoint"
  value       = module.data.db_endpoint
}

#################################
# Storage
#################################
output "assets_bucket_name" {
  description = "S3 bucket storing static assets"
  value       = module.assets.bucket_name
}

#################################
# Networking
#################################
output "network_id" {
  description = "Primary VPC ID"
  value       = module.network.vpc_id
}
