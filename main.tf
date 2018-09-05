
data "aws_ami" "openvpnas" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "*${var.user_license[var.user_count]}*"
    ]
  }

  owners = [
    "679593333241",
  ]
}

resource "aws_security_group" "openvpn" {
  name        = "${var.name}"
  vpc_id      = "${var.vpc_id}"
  description = "OpenVPN security group"
  tags        = "${merge(var.tags, map("Name", "${var.name}-sg"))}"
}

resource "aws_security_group_rule" "ingress_vpcall" {
  type        = "ingress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["${var.vpc_cidr}"]

  security_group_id = "${aws_security_group.openvpn.id}"
}

resource "aws_security_group_rule" "ingress_tcp443" {
  type        = "ingress"
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.openvpn.id}"
}

resource "aws_security_group_rule" "ingress_udp1194" {
  type        = "ingress"
  protocol    = "udp"
  from_port   = 1194
  to_port     = 1194
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.openvpn.id}"
}

resource "aws_security_group_rule" "egress_all" {
  type        = "egress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.openvpn.id}"
}

data "template_file" "user-data" {
  template = "${file("./modules/openvpn/userData.sh")}"
  vars {
    admin_user  = "${var.admin_user}"
    admin_pw    = "${var.admin_password}"
    split_tunnel = "${var.split_tunnel}"
  }
}

resource "aws_instance" "openvpn" {
  ami                    = "${data.aws_ami.openvpnas.id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  subnet_id              = "${element(var.public_subnet_ids, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.openvpn.id}"]
  iam_instance_profile   = "${var.instance_profile}"
  tags                   = "${merge(var.tags, map("Name", "${var.name}"))}"
  volume_tags            = "${merge(var.tags, map("Name", "${var.name}-vol"))}"

  lifecycle {
    ignore_changes = ["user_data", "ami"]
  }

  user_data = "${data.template_file.user-data.rendered}"

}

resource "aws_eip" "vpn" {
  vpc  = true
  tags = "${var.tags}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip_association" "eip_vpn" {
  instance_id   = "${aws_instance.openvpn.id}"
  allocation_id = "${aws_eip.vpn.id}"
}

resource "aws_route53_record" "openvpn" {
  count   = "${length(var.hosted_zone) > 0 ? 1 : 0}"
  zone_id = "${var.hosted_zone}"
  name    = "vpn"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.vpn.public_ip}"]
}

