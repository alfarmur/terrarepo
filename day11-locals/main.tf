locals {
  bucket-name = "${var.layer}-${var.env}-yabkt"
  region = "us-west-2"
  #provider = aws.oregon
}

resource "aws_s3_bucket" "demo" {
    # bucket = "web-dev-bucket"
    # bucket = "${var.layer}-${var.env}-bucket-hyd"
    bucket = local.bucket-name
    region = local.region
    #provider = local.provider
    tags = {
        # Name = "${var.layer}-${var.env}-bucket-hyd"
        Name = local.bucket-name
        Environment = var.env
    }
    

  
}


# locals {
#   region        = "us-east-1"
#   instance_type = "t2.micro"
# }

# resource "aws_instance" "example" {
#   ami           = "ami-123456"
#   instance_type = local.instance_type
#   tags = {
#     Name = "App-${local.region}"
#   }
# }