# Mongo-app security group
resource "aws_security_group" "mongo_app" {
  vpc_id      = "${var.vpc_id}"
  name        = "mongo_app"
  description = "Security group for apps that needs access to mongodb"

  tags {
    Name        = "mongo_app"
    Environment = "${var.environment}"
  }
}

# MongoDB security group
resource "aws_security_group" "mongodb" {
  vpc_id      = "${var.vpc_id}"
  name        = "mongodb"
  description = "Security group for mongodb"

  tags {
    Name        = "mongodb"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "mongodb_allow_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.mongodb.id}"
}

# Allow all MongoDBs in the same security group communicate between each others
resource "aws_security_group_rule" "mongodb_mongodb" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27019
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.mongodb.id}"
  security_group_id        = "${aws_security_group.mongodb.id}"
}

# Allow apps using mongodb connect to mongodb
resource "aws_security_group_rule" "mongo_app_mongodb" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.mongo_app.id}"
  security_group_id        = "${aws_security_group.mongodb.id}"
}

# Allow all bastion hosts ssh to mongodbs
resource "aws_security_group_rule" "bastion_mongodb" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${var.security_group_bastion}"
  security_group_id        = "${aws_security_group.mongodb.id}"
}

# Allow all bastion hosts ping to mongodbs
resource "aws_security_group_rule" "bastion_ping_mongodb" {
  type                     = "ingress"
  from_port                = 8
  to_port                  = 0
  protocol                 = "icmp"
  source_security_group_id = "${var.security_group_bastion}"
  security_group_id        = "${aws_security_group.mongodb.id}"
}

# Allow all bastion hosts connect to default mongodbs port for data access
resource "aws_security_group_rule" "bastion_dbconnect_mongodb" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = "${var.security_group_bastion}"
  security_group_id        = "${aws_security_group.mongodb.id}"
}

# MongoDB instances

resource "aws_instance" "mongodb" {
  count                  = "${length(var.availability_zones) - (var.enable_arbiter ? 1 : 0)}"
  ami                    = "${var.ami}"
  instance_type          = "${var.mongodb_instance_type}"
  key_name               = "${var.key_name}"
  availability_zone      = "${element(var.availability_zones, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.mongodb.id}"]
  subnet_id              = "${element(var.subnet_ids, count.index)}"
  monitoring             = true
  ebs_optimized          = "${var.ebs_optimized}"

  tags {
    Name        = "mongodb_${count.index}"
    ReplicaSet  = "${var.replicaset_name}"
    Role        = "mongodb"
    Environment = "${var.environment}"
  }

  volume_tags {
    Name        = "mongodb_${count.index}"
    Environment = "${var.environment}"
  }
}

# Data volume for MongoDb
resource "aws_ebs_volume" "mongodb_data_volume" {
  count             = "${length(var.availability_zones) - (var.enable_arbiter ? 1 : 0)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  type              = "gp2"
  size              = "${var.ebs_volume_size}"
  encrypted         = true

  tags {
    Name        = "mongodb_${count.index}_data"
    Role        = "data"
    Environment = "${var.environment}"
  }
}

resource "aws_volume_attachment" "mongodb_data_volume_attachment" {
  count       = "${length(var.availability_zones) - (var.enable_arbiter ? 1 : 0)}"
  device_name = "/dev/sdf"
  volume_id   = "${element(aws_ebs_volume.mongodb_data_volume.*.id, count.index)}"
  instance_id = "${element(aws_instance.mongodb.*.id, count.index)}"
}

# Optional arbiter instance of MongoDb
resource "aws_instance" "mongodb_arbiter" {
  count                  = "${var.enable_arbiter ? 1 : 0}"
  ami                    = "${var.arbiter_ami}"
  instance_type          = "${var.arbiter_instance_type}"
  key_name               = "${var.key_name}"
  availability_zone      = "${element(var.availability_zones, length(var.availability_zones) - 1)}"
  vpc_security_group_ids = ["${aws_security_group.mongodb.id}"]
  subnet_id              = "${element(var.subnet_ids, length(var.availability_zones) - 1)}"

  tags {
    Name        = "mongodb_arbiter"
    ReplicaSet  = "${var.replicaset_name}"
    Role        = "arbiter"
    Environment = "${var.environment}"
  }
}
