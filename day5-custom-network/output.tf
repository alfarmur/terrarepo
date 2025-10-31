output "public_ip-Bastion" {
  value = aws_instance.bastionec2.public_ip
}

output "private_ip-bastion" {
  value = aws_instance.bastionec2.private_ip
}

output "private_ip-terraec2" {
  value = aws_instance.ec2.private_ip
}

output "bastion-availability_zone" {
  value = aws_instance.bastionec2.availability_zone
}

output "ec2-az" {
  value = aws_instance.ec2.availability_zone
}