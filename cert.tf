
# Generate ssl cert for openvpn server

provider "acme" {
#  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "account_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = "${tls_private_key.account_key.private_key_pem}"
  email_address   = "support@bluesentryit.com"
}


resource "tls_private_key" "cert_key" {
  algorithm = "RSA"
}

locals {
  domain_name = "${var.dns_server_name}.${replace(data.aws_route53_zone.subdomain.name, "/[.]$/", "")}"
}

resource "tls_cert_request" "request" {
  key_algorithm = "RSA"
  private_key_pem = "${tls_private_key.cert_key.private_key_pem}"
  dns_names = ["${local.domain_name}"]

  subject {
    common_name = "${local.domain_name}"
  }
}

resource "acme_certificate" "cert" {
  account_key_pem           = "${acme_registration.reg.account_key_pem}"
  certificate_request_pem   = "${tls_cert_request.request.cert_request_pem}"

  dns_challenge {
    provider = "route53"
  }
}
