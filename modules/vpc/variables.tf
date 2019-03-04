variable "base_cidr_block" {
  default = "10.0.0.0/16"
}

variable "cidr_newbits" {
  description = "New bits to add in order to get network mask for subnets. E.g. we split our /16 VPC to /20 subnets => 20-16=4"
  default = 4
}

variable "cidr_netnum_public" {
  description = "Index of subnets, where public subnets begin. The default splits /16 to 16 different /20 subnets. We reserve indexes 0-7 to private subnets and rest 8-15 to public ones."
  default = 8
}

# Index of subnets, where private subnets begin same was as abowe
variable "cidr_netnum_private" {
  default = 0
}

variable "environment" {
  description = "Environment of the module. E.g. Development, Testing, Staging, Production"  
}

variable "availability_zones" {
  description = "Availability Zones for EC2 resources"
  type = "list"
}

variable "enable_nat_gateway" {
  description = "If nat gateway is used instead of nat instances. If false, then ami for nat instances must be provided (nat_intance_ami)."
  default = false
}

variable "nat_instance_ami" {
  description = "ami for nat intances. Required only if nat gateway is not enabled."
}

variable "nat_instance_type" {
  description = "EC2 Instance type to use with nat-intances."
  default = "t2.micro"
}

variable "bastion_host_ami" {
  description = "ami for bastion host intances."
}

variable "bastion_instance_type" {
  description = "EC2 Instance type to use with bastion hosts."
  default = "t2.micro"
}

variable "key_name" {
  description = "SSH key name to use with EC2 instances"
}