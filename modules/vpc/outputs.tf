output "vpc_id" {
  description = "Id of the created vpc"
  value = "${aws_vpc.main.id}"
}

output "private_subnets" {
  description = "List of ids of private subnets"
  value = ["${aws_subnet.private.*.id}"]
}

output "public_subnets" {
  description = "List of ids of public subnets"
  value = ["${aws_subnet.public.*.id}"]
}

output "security_group_bastion" {
  description = "Id of bastion host security group"
  value = "${aws_security_group.bastion.id}" 
}
