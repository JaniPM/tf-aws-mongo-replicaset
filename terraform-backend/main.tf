provider "aws" {
  region = "${var.region}"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tf-state" {
  bucket = "example-terraform-state"
  acl = "private"
  region = "${var.region}"

  versioning {
    enabled = true
  }

  tags {
    Name = "Example Terraform State"
  }
}
