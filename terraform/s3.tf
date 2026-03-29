resource "aws_s3_bucket" "django_media" {
  bucket = "sohail-django-media-bucket"

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

resource "aws_s3_bucket_ownership_controls" "django_media" {
  bucket = aws_s3_bucket.django_media.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "django_media" {
  depends_on = [
    aws_s3_bucket_public_access_block.django_media,
    aws_s3_bucket_ownership_controls.django_media
  ]

  bucket = aws_s3_bucket.django_media.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "django_media_policy" {
  bucket = aws_s3_bucket.django_media.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.django_media.arn}/*"
      }
    ]
  })
}
