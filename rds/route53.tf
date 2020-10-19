###########################################
# Route53
###########################################

data "aws_route53_zone" "example" {
  name = var.domain
}

resource "aws_route53_record" "example" {
  zone_id = data.aws_route53_zone.example.zone_id
  name    = data.aws_route53_zone.example.name
  type    = "A"

  alias {
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

output "domain_name" {
  value = aws_route53_record.example.name
}

###########################################
# ACM
###########################################

resource "aws_acm_certificate" "example" {
  domain_name               = aws_route53_record.example.name
  subject_alternative_names = []    # ドメイン名を追加する場合に設定。eg.["test.example.com"]
  validation_method         = "DNS" # ドメイン所有権の検証方法 EMAIL or DNS

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "example_certificate" {
  # ver3.0以降ではlist形式からset形式に変更されているため、for/for_eachを使用する
  # name    = aws_acm_certificate.example.domain_validation_options[0].resource_record_name
  # type    = aws_acm_certificate.example.domain_validation_options[0].resource_record_type
  # records = [aws_acm_certificate.example.domain_validation_options[0].resource_record_value]
  for_each = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]

  ttl        = 60
  depends_on = [aws_acm_certificate.example]
  zone_id    = data.aws_route53_zone.example.id

}

# 検証の待機
# apply時にSSL証明書の検証が完了するまで待機する

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.example.arn
  validation_record_fqdns = [for record in aws_route53_record.example_certificate : record.fqdn]
}

