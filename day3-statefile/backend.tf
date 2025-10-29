terraform {
  backend "s3" {
    bucket = "yaterrastatefile"
    key="day3/terraform.tfstate"
    region = "us-east-1"
  }
}