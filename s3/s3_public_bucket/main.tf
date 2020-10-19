##################################
# Public Bucket
##################################

resource "aws_s3_bucket" "public" {
  bucket = "public-pragmatic-terraform_20201018"
  acl    = "public-read" # インターネットからの読み込みを許可

  versioning {
    enabled = true
  }
  # CORS
  cors_rule {
    allowed_origins = ["https://example.com"] # 任意のドメイン
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000

  }
}