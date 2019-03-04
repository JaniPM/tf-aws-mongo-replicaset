# Prerequisite: 
# Terraform can automatically search AWS access keys from ~/.aws/credentials
# Make sure to initialize this file with correct keys
# https://aws.amazon.com/blogs/apn/terraform-beyond-the-basics-with-aws/

provider "aws" {
  region = "${var.region}"
}

data "aws_caller_identity" "current" {}

terraform {
  # Terraform can store it's state to s3 bucket. Create one and upadte the variables here.
  backend "s3" {
    bucket = "example-terraform-state"
    key    = "terraform/production/terraform.tfstate"
    region = "eu-west-1"
  }
}

module "vpc" {
  base_cidr_block    = "192.168.0.0/16"
  source             = "../modules/vpc"
  environment        = "production"
  enable_nat_gateway = false
  nat_instance_ami   = "${lookup(var.nat_instance_ami, var.region)}"
  bastion_host_ami   = "${lookup(var.bastion_host_ami, var.region)}"
  key_name           = "example_ssh_key_to_production"
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

module "mongodb" {
  source                 = "../modules/mongodb"
  environment            = "production"
  key_name               = "example_ssh_key_to_production"
  ebs_volume_size        = 100
  replicaset_name        = "no_replica_set"
  availability_zones     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_id                 = "${module.vpc.vpc_id}"
  security_group_bastion = "${module.vpc.security_group_bastion}"
  subnet_ids             = "${module.vpc.private_subnets}"
  ami                    = "${lookup(var.mongodb_ami, var.region)}"
  arbiter_ami            = "${lookup(var.mongodb_arbiter_ami, var.region)}"
  enable_arbiter         = true
  mongodb_instance_type  = "t2.medium"
  ebs_optimized          = false
}
