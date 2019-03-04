variable "region" {
  default = "eu-west-1"
}

variable "mongodb_ami" {
  description = "ami for mongodb instances"
  type        = "map"

  default = {
    "eu-west-1" = "ami-e2adf99e"
  }
}

# TODO just query the latest micro Amazon Linux for arbiter
variable "mongodb_arbiter_ami" {
  description = "ami for mongodb arbiter instances"
  type        = "map"

  default = {
    "eu-west-1" = "ami-e2adf99e"
  }
}

# TODO just query the latest one that is Amazon Linux configured as nat instance
# Note for nat instance we use amzn-ami-vpc-nat-hvm instance since they are preconfigured for nat
variable "nat_instance_ami" {
  description = "ami for nat instances"
  type        = "map"

  default = {
    "eu-west-1" = "ami-76aafe0a"
  }
}

# TODO just query the latest micro Amazon Linux for bastion hosts
variable "bastion_host_ami" {
  description = "ami for bastion host instances"
  type        = "map"

  default = {
    "eu-west-1" = "ami-e2adf99e"
  }
}
