data "aws_route53_zone" "default" {
  name = var.domain
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.default.zone_id
  name    = "frourio.${var.domain}"
  type    = "A"
  alias {
    name                   = aws_lb.service.dns_name
    zone_id                = aws_lb.service.zone_id
    evaluate_target_health = true
  }
}
