terraform {
  backend "s3" {
    bucket = "ya-statelock"
    key="day4/terraform.tfstate"
    region = "us-east-1"
  }
}