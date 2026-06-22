# site.tf — hosts the dashboard as a public S3 static website.

resource "aws_s3_bucket" "site" {
  # Bucket names are globally unique, so we suffix with the account id.
  bucket = "${var.project_name}-site-${data.aws_caller_identity.current.account_id}"
}

# Turn the bucket into a website (serves index.html at the root).
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  index_document {
    suffix = "index.html"
  }
}

# A static website must be publicly readable, so we turn OFF the default
# "block public access" guard for THIS bucket only.
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Allow anyone to read (GET) objects — but only read, nothing else.
data "aws_iam_policy_document" "site_public_read" {
  statement {
    sid       = "PublicRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket     = aws_s3_bucket.site.id
  policy     = data.aws_iam_policy_document.site_public_read.json
  depends_on = [aws_s3_bucket_public_access_block.site]
}

# Upload the dashboard page. The etag re-uploads it whenever the file changes.
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/../frontend/index.html"
  etag         = filemd5("${path.module}/../frontend/index.html")
  content_type = "text/html"
}
