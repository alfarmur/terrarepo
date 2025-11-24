data "aws_route53_zone" "main" {
  name         = "187296253949.realhandsonlabs.net"
  private_zone = false
}
# Frontend ALB Route53 alias
resource "aws_route53_record" "frontend_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "frontend.${data.aws_route53_zone.main.name}"   # frontend.realhandsonlabs.net
  type    = "A"

  alias {
    name                   = aws_lb.frontend_alb.dns_name
    zone_id                = aws_lb.frontend_alb.zone_id
    evaluate_target_health = true
  }
}

# Backend ALB Route53 alias
resource "aws_route53_record" "backend_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "backend.${data.aws_route53_zone.main.name}"    # backend.realhandsonlabs.net
  type    = "A"

  alias {
    name                   = aws_lb.backend_alb.dns_name
    zone_id                = aws_lb.backend_alb.zone_id
    evaluate_target_health = true
  }
}
