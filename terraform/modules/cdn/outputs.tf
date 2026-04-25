output "cloudfront_domain" {
  value = aws_cloudfront_distribution.main.domain_name
}

output "oac_id" {
  value = aws_cloudfront_origin_access_control.s3_oac.id
}
