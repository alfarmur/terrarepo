# 1. Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = "192.68.0.0/16"

  tags = {
    Name = "my-vpc-new"
  }
}
