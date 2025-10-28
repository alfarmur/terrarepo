output "public_ip" {
  value = aws_instance.name.public_ip
}

output "private_ip" {
  value = aws_instance.name.private_ip
}

output "availability_zone" {
  value = aws_subnet.public_subnet_1.availability_zone
}

output "az_subnet2" {
  value = aws_subnet.public_subnet_2.availability_zone
}