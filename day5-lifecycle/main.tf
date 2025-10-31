resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/24"

 lifecycle {
     create_before_destroy = true
     #prevent_destroy       = true
     #ignore_changes        = [tags]
  }

  tags = {
    Name = "test"
  }
}
