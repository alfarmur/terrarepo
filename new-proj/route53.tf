###############################################
# ROUTE53 PRIVATE ZONE FOR RDS
###############################################

resource "aws_route53_zone" "private_zone" {
  name = "internal.local"
  vpc {
    vpc_id = aws_vpc.three_tier.id
  }
}

resource "aws_route53_record" "rds_alias" {
  zone_id = aws_route53_zone.private_zone.zone_id
  name    = "db.internal.local"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.rds.address]
}
