resource "aws_s3_bucket" "main" {
  bucket        = "${var.project_name}-${var.environment}-assets-${random_id.suffix.hex}"
  force_destroy = true

  tags = { Name = "${var.project_name}-${var.environment}-assets", Project = var.project_name }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access — CloudFront uses OAC instead
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

# Bucket policy — allow CloudFront OAC to read objects
resource "aws_s3_bucket_policy" "cloudfront_oac" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid = "AllowCloudFrontOAC"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action = "s3:GetObject"
      Resource = "${aws_s3_bucket.main.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = "arn:aws:cloudfront::*:distribution/*"
        }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.main]
}
