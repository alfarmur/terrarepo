# ===============================
# OUTPUTS
# ===============================
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_private_key_pem" {
  description = "PEM private key for bastion (sensitive)"
  value       = tls_private_key.bastion_key.private_key_pem
  sensitive   = true
}


output "rds_endpoint" {
  value     = aws_db_instance.mysql.endpoint
  sensitive = false
}

output "rds_address" {
  value = aws_db_instance.mysql.address
}
# ===============================
# Outputs for ALBs
# ===============================

output "backend_alb_dns" {
  description = "Public DNS of the backend ALB"
  value       = aws_lb.backend_alb.dns_name
}

output "frontend_alb_dns" {
  description = "Public DNS of the frontend ALB"
  value       = aws_lb.frontend_alb.dns_name
}

# ===============================
# Outputs for Route53 alias records
# ===============================

output "frontend_domain_name" {
  description = "Frontend domain mapped via Route53 alias"
  value       = aws_route53_record.frontend_alias.fqdn
}

output "backend_domain_name" {
  description = "Backend domain mapped via Route53 alias"
  value       = aws_route53_record.backend_alias.fqdn
}

