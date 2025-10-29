terraform {
  backend "s3" {
    bucket = "yaterrastatefile"
    key="day2/terraform.tfstate"
    region = "us-east-1"
  }
}
