

output "public_ip" {
  value = "${aws_instance.openvpn.public_ip}"
}

output "security_group" {
  value = "${aws_security_group.openvpn.id}"
}