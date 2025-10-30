terraform {
  backend "s3" {
    bucket = "ya-statelock"
    key="day4/terraform.tfstate"
    dynamodb_table = "yalockdb"
    encrypt = true
    region = "us-east-1"
  }
}