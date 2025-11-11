resource "aws_instance" "name" {
  ami="ami-0cae6d6fe6048ca2c" 
  instance_type = "t2.micro"

}

resource "aws_s3_bucket" "name" {
    bucket = "yabktmine-unique"
    provider = aws.other
  
}