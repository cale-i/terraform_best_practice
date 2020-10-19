##################################
# Log Bucket
##################################

resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-pragmatic-terraform_20201018"

  # 180日経過したファイルを自動削除
  lifecycle_rule {
    enabled = true
    expiration {
      days = "180"
    }
  }
}

##################################
# Bucket Policy for ALB
##################################

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["<書き込みを行うアカウントID>"]
    }
  }
}