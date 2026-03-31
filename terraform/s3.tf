resource "aws_s3_bucket" "django_media" {
  bucket        = "sohail-django-media-bucket"
  force_destroy = true

  tags = {
    Name        = "django-media-bucket"
    Environment = "dev"
    Project     = "devops-ecommerce-platform"
  }
}

resource "aws_s3_bucket_public_access_block" "django_media" {
  bucket = aws_s3_bucket.django_media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "django_media" {
  bucket = aws_s3_bucket.django_media.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "django_media" {
  bucket = aws_s3_bucket.django_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
