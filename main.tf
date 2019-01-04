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

data "aws_vpc" "main" {
  id = "${var.vpc_id}"
}

resource "aws_security_group" "openvpn" {

  vpc_id      = "${var.vpc_id}"
  description = "OpenVPN security group"
  tags        = "${merge(var.tags, map("Name", "${var.name}-sg"))}"
}

resource "aws_security_group_rule" "ingress_vpcall" {
  type        = "ingress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["${data.aws_vpc.main.cidr_block}"]

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

data "external" "whatsmyip" {
  program = ["bash", "-c", "echo '{\"internet_ip\":\"'$(dig +short myip.opendns.com @resolver1.opendns.com)'\"}'"]
}
resource "aws_security_group_rule" "allow_ssh_from_my_ip" {
  count             = "${length(data.external.whatsmyip.result["internet_ip"]) > 0 ? 1 : 0}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["${data.external.whatsmyip.result["internet_ip"]}/32"]
  security_group_id = "${aws_security_group.openvpn.id}"
  description       = "BSI terraform automation access"
}

resource "aws_security_group_rule" "egress_all" {
  type        = "egress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.openvpn.id}"
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

  user_data = <<USERDATA
    admin_user=${var.admin_user}
    admin_pw=${data.aws_secretsmanager_secret_version.vpnadmin.secret_string}
  USERDATA
}

resource "null_resource" "provision" {
  count   = "${length(var.hosted_zone) > 0 ? 1 : 0}"

  triggers {
    dns_id      = "${aws_route53_record.openvpn.id}"
    instance_id = "${aws_instance.openvpn.id}"
    cert        = "${acme_certificate.cert.certificate_pem}"
  }

  connection {
    type        = "ssh"
    user        = "openvpnas"
    host        = "${aws_eip.vpn.public_ip}"
    private_key = "${var.ssh_private_key}"
  }

  provisioner "remote-exec" {
    inline = [

      # give openvpn time to come online
      "sleep 30",

      # add entry to host file, so sudo doesn't throw 'unable to resolve host'
      "echo '${element(split(".", aws_instance.openvpn.private_dns), 0)}'",
      "sudo sed -i 's/127.0.0.1 localhost/127.0.0.1 localhost ${element(split(".", aws_instance.openvpn.private_dns), 0)}/g' /etc/hosts",

      # update hostname in config
      "sudo /usr/local/openvpn_as/scripts/sacli --key host.name --value ${element(null_resource.domain.*.triggers.domain_name, 0)} ConfigPut",

      # update with ssl cert
      "sudo /usr/local/openvpn_as/scripts/sacli --key cs.priv_key --value '${tls_private_key.cert_key.private_key_pem}' ConfigPut",
      "sudo /usr/local/openvpn_as/scripts/sacli --key cs.cert --value '${acme_certificate.cert.certificate_pem}' ConfigPut",
      "sudo /usr/local/openvpn_as/scripts/sacli --key cs.ca_bundle --value '${acme_certificate.cert.issuer_pem}' ConfigPut",

      # Do a warm retart
      "sudo /usr/local/openvpn_as/scripts/sacli start"
    ]
  }
}

resource "null_resource" "zones" {
  count = "${length(var.private_zones) > 0 ? 1 : 0}"

  triggers {
    zones = "${var.private_zones}"
  }

  connection {
    type        = "ssh"
    user        = "openvpnas"
    host        = "${aws_eip.vpn.public_ip}"
    private_key = "${var.ssh_private_key}"
  }

  provisioner "remote-exec" {
    inline = [

      # private dns zone
      "sudo /usr/local/openvpn_as/scripts/sacli --key vpn.server.dhcp_option.domain --value '${var.private_zones}' ConfigPut",
      "sudo /usr/local/openvpn_as/scripts/sacli --key vpn.client.routing.reroute_dns --value 'true' ConfigPut",

      # Do a warm retart
      "sudo /usr/local/openvpn_as/scripts/sacli start"
    ]
  }

  depends_on = ["null_resource.provision"]
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

data "aws_route53_zone" "subdomain" {
  count   = "${length(var.hosted_zone) > 0 ? 1 : 0}"
  zone_id = "${var.hosted_zone}"
}
resource "aws_route53_record" "openvpn" {
  count   = "${length(var.hosted_zone) > 0 ? 1 : 0}"
  zone_id = "${var.hosted_zone}"
  name    = "${var.dns_server_name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.vpn.public_ip}"]
}

# Add secret for storing vpnadmin password
resource "aws_secretsmanager_secret" "vpnadmin" {
  name        = "${length(var.secret_name) > 0 ? var.secret_name : "vpnadmin_pass"}"
  description = "Password for openvpn admin user (${var.admin_user})"
  tags        = "${var.tags}"
}
resource "aws_secretsmanager_secret_version" "vpnadmin" {
  secret_id     = "${aws_secretsmanager_secret.vpnadmin.id}"
  secret_string = "${var.admin_password}"
  lifecycle {
    ignore_changes = ["secret_string"]
  }
}
data "aws_secretsmanager_secret_version" "vpnadmin" {
  secret_id = "${aws_secretsmanager_secret.vpnadmin.id}"
}