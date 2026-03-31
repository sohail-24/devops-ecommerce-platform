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

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
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

resource "aws_s3_bucket_ownership_controls" "django_media" {
  bucket = aws_s3_bucket.django_media.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "django_media_public_read" {
  bucket = aws_s3_bucket.django_media.id

  depends_on = [
    aws_s3_bucket_public_access_block.django_media
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.django_media.arn}/*"
      }
    ]
  })
}
