# variable "aws_region" {
#   description = "The region in which to create the infrastructure"
#   type        = string
#   nullable    = false
#   default     = "us-east-1" #here we need to define either in given region only,  if i give other region will get error 
#   validation {
#     condition = var.aws_region == "us-east-1" || var.aws_region == "us-west-2"
#     error_message = "The variable 'aws_region' must be one of the following regions: us-east-1, us-west-2"
#   }
# }

# provider "aws" {
#   region = "us-east-1"
#  }

#  resource "aws_s3_bucket" "dev" {
#     bucket = "yabkt-mine"
# }

#after run this will get error like The variable 'aws_region' must be one of the following regions: us-west-2,│ eu-west-1, so it will allow any one region defined above in conditin block



### Example-2
# variable "create_bucket" {
#   type    = bool
#   default = false
# }

# resource "aws_s3_bucket" "example" {
#   count  = var.create_bucket ? 1 : 0
#   bucket = "my-terraform-example"
# }

## Example-3
variable "environment" {
  type    = bool
  default = true
}

resource "aws_instance" "example" {
  count         = var.environment ? 2 : 1
  ami           = "ami-0cae6d6fe6048ca2c"
  instance_type = "t2.micro"

  tags = {
    Name = "example-${count.index}"
  }
}

# #In this case:
# #If var.environment == "prod" → count = 3
# #Else (like dev, qa, etc.) → count = 1
# #terraform apply -var="environment=dev"