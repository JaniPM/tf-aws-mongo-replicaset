resource "aws_vpc" "main" {
  cidr_block = "${var.base_cidr_block}"
  enable_dns_hostnames = true
  tags {
    Name = "main_${var.environment}"
    Environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "main"
    Environment = "${var.environment}"
  }
}

################################################################################
# Subnets
################################################################################

# Private subnets
resource "aws_subnet" "private" {
  count = "${length(var.availability_zones)}"
  vpc_id = "${aws_vpc.main.id}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  cidr_block = "${cidrsubnet(
    aws_vpc.main.cidr_block, 
    var.cidr_newbits, 
    var.cidr_netnum_private + count.index
  )}"

  tags {
    Name = "private_${count.index}"
    Environment = "${var.environment}"
  }
}

# Public subnets
resource "aws_subnet" "public" {
  count = "${length(var.availability_zones)}"
  vpc_id = "${aws_vpc.main.id}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true

  cidr_block = "${cidrsubnet(
    aws_vpc.main.cidr_block, 
    var.cidr_newbits, 
    var.cidr_netnum_public + count.index
  )}"

  tags {
    Name = "public_${count.index}"
    Environment = "${var.environment}"
  }
}

################################################################################
# Nat gateways/intances
################################################################################

# Create nat gateway with elastic ip to each public subnet, if enabled
resource "aws_eip" "nat_eip" {
  count = "${length(var.availability_zones) * var.enable_nat_gateway}"
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  count = "${length(var.availability_zones) * var.enable_nat_gateway}"
  allocation_id = "${element(aws_eip.nat_eip.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  depends_on = ["aws_internet_gateway.main"]
}

# If nat gateway is not enabled, create nat instances

# Security group for nat instances.
resource "aws_security_group" "nat_instance" {
  count = "${1 - var.enable_nat_gateway}"
  vpc_id = "${aws_vpc.main.id}"
  name = "nat_instance"
  description = "Allow traffic from clients into NAT instances"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["${aws_subnet.private.*.cidr_block}"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.private.*.cidr_block}"]
  }

  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["${aws_subnet.private.*.cidr_block}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${aws_subnet.public.*.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Nat-instances. Created only if nat-gateway is not enabled.
resource "aws_instance" "nat_instance" {
  count = "${length(var.availability_zones) * (1 - var.enable_nat_gateway)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  key_name = "${var.key_name}"
  ami = "${var.nat_instance_ami}"
  instance_type = "${var.nat_instance_type}"
  source_dest_check = false
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.nat_instance.id}"]

  lifecycle {
    # Ignore changes to the NAT AMI data source.
    ignore_changes = ["ami"]
  }

  tags {
    Name = "nat_instance_${count.index}"
    Environment = "${var.environment}"
  }
}

# TODO should elastic IP be used with instances or not

################################################################################
# Route tables
################################################################################

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"
  count = "${length(var.availability_zones)}"
  tags { 
    Name = "private_subnet_${count.index}"
    Environment = "${var.environment}"
  }
}

# Route from private subnets to nat-gateways if enabled
resource "aws_route" "private_nat_gateway_route" {
  count = "${length(var.availability_zones) * var.enable_nat_gateway}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${element(aws_nat_gateway.nat_gw.*.id, count.index)}"
}

# Route from private subnets to nat-instance if gateways are disabled
resource "aws_route" "internal_nat_instance" {
  count = "${length(var.availability_zones) * (1 - var.enable_nat_gateway)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  instance_id = "${element(aws_instance.nat_instance.*.id, count.index)}"
}

resource "aws_route_table_association" "private" {
  count = "${length(var.availability_zones)}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

# Route public subnets to internet gateway
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "public_subnets"
    Environment = "${var.environment}"
  }
}

resource "aws_route" "public" {
  route_table_id = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.main.id}"
}

resource "aws_route_table_association" "public" {
  count = "${length(var.availability_zones)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

################################################################################
# Bastion host to access instances
################################################################################

# Security for bastion hosts
resource "aws_security_group" "bastion" {
  vpc_id = "${aws_vpc.main.id}"
  name = "bastion"
  description = "Security group for bastion hosts"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "bastion"
    Environment = "${var.environment}"
  }
}

# Bastion host instance
# We add this only to first availability zone at the moment. 
# Improvement is to add it under availability group
resource "aws_instance" "bastion_host" {
  availability_zone = "${element(var.availability_zones, 0)}"
  key_name = "${var.key_name}"
  ami = "${var.bastion_host_ami}"
  instance_type = "${var.bastion_instance_type}"
  subnet_id = "${element(aws_subnet.public.*.id, 0)}"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]

  tags {
    Name = "bastion_host"
    Environment = "${var.environment}"
  }
}
