terraform {
  backend "s3" {                             # Backend designation
    bucket = "${var.s3_bucket}"              # Bucket name
    key = "${var.key_bucket}"                # Key
    region = "${var.backend_region}"                 # Region
    encrypt = true                           # Encryption enabled
    dynamodb_table = "${var.dynamodb_table}"
    profile = "${var.backend_profile}"
  }
  # backend "s3" {                             # Backend designation
  #   bucket = "${var.s3_bucket}"              # Bucket name
  #   key = "${var.key_bucket}"                # Key
  #   region = "${var.region}"                 # Region
  #   encrypt = true                           # Encryption enabled
  #   dynamodb_table = "${var.dynamodb_table}"
  #   # profile = "${var.profile}"
  # }
  required_version = ">= 0.12"
}

# Using the AWS Provider
# https://www.terraform.io/docs/providers/
provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
  # shared_credentials_file = var.aws_creds_file_path
  version = "~> 2.17"
}

# Resource random to generate random characters
# resource "random_string" "name" { 
#   length = 6
#   special = false
#   upper = false
# }
