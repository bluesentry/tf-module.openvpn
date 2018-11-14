
# Generate ssl cert for openvpn server

provider "acme" {
#  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "account_key" {
  count     = "${length(var.hosted_zone) > 0 ? 1 : 0}"
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  count           = "${length(var.hosted_zone) > 0 ? 1 : 0}"
  account_key_pem = "${tls_private_key.account_key.private_key_pem}"
  email_address   = "support@bluesentryit.com"
}


resource "tls_private_key" "cert_key" {
  count     = "${length(var.hosted_zone) > 0 ? 1 : 0}"
  algorithm = "RSA"
}

resource "null_resource" "domain" {
  count = "${length(var.hosted_zone) > 0 ? 1 : 0}"

  triggers {
    domain_name = "${var.dns_server_name}.${replace(data.aws_route53_zone.subdomain.name, "/[.]$/", "")}"
  }
}

resource "tls_cert_request" "request" {
  count           = "${length(var.hosted_zone) > 0 ? 1 : 0}"
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.cert_key.private_key_pem}"
  dns_names       = ["${null_resource.domain.*.triggers.domain_name}"]

  subject {
    common_name = "${element(null_resource.domain.*.triggers.domain_name, 0)}"
  }
}

resource "acme_certificate" "cert" {
  count                     = "${length(var.hosted_zone) > 0 ? 1 : 0}"
  account_key_pem           = "${acme_registration.reg.account_key_pem}"
  certificate_request_pem   = "${tls_cert_request.request.cert_request_pem}"

  dns_challenge {
    provider = "route53"
  }
}
