variable "environment" {
  description = "Environment of the module. E.g. Development, Testing, Staging, Production"  
}

variable "ami" {
  description = "EC2 ami to use for new mongodb virtual machine"
}

variable "arbiter_ami" {
  description = "EC2 ami to use for new mongodb arbiter virtual machine"
}

variable "key_name" {
  description = "EC2 Key Name"
}

variable "mongodb_instance_type" {
  description = "EC2 Instance type to use with dabases. E.g. m4.medium"
  default = "t2.micro"
}

variable "enable_arbiter" {
  description = "Should we use arbiter as an additional instance? (true/false)"
  default = false
}

variable "arbiter_instance_type" {
  description = "EC2 Instance type to use with arbiter."
  default = "t2.micro"
}

variable "replicaset_name" {
  description = "Replica set name for MongoDB. Used for tags only"
}

variable "ebs_volume_size" {
  description = "Size of the EBS Block Device used for data files"
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  default = false
}

variable "availability_zones" {
  description = "Availability Zones for EC2 resources"
  type = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "subnet_ids" {
  description = "Ids of subnets where to create mongodb instances"
  type = "list"
}

variable "vpc_id" {
  description = "Id of the VPC where to place MongoDB instances"
}

variable "security_group_bastion" {
  description = "Id of the bastion host security group"
}