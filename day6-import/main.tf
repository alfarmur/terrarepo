#keep main.tf empty and give provider.tf)
#Terraform init
#Terraform import aws_vpc.vpc <vpcid-copy from console>
#Terraform aws_s3_bucket.bkkname <bucket name>
#Check terraform.tfstate and collect needed information like vpc tag, its cidr.. and modify main code accordingly.
#Terraform plan(terraform plan
#Terraform will show differences between .tf file and the actual AWS resource. adjust main resource code to match the current state configuration, until no changes.)


resource "aws_vpc" "vpc" {
  cidr_block = "192.68.0.0/16"
  tags = {
    Name = "my-vpc"
          }
}

resource "aws_s3_bucket" "bktname" {
  bucket = "yabkt"
}