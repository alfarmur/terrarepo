###############################################
# OUTPUTS
###############################################

output "backend_ami_id" {
  value = data.aws_ami.backend.id
}

output "backend_lt_id" {
  value = aws_launch_template.backend.id
}

output "backend_asg_name" {
  value = aws_autoscaling_group.backend_asg.name
}

output "rds_internal_dns" {
  description = "Private Route53 record name for RDS"
  value       = aws_route53_record.rds_alias.fqdn
}

output "rds_endpoint" {
  description = "The RDS instance endpoint address"
  value       = aws_db_instance.rds.address
}
