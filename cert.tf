
# Generate ssl cert for openvpn server

provider "acme" {
#  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "account_key" {
  count     = var.enable_acme_cert == true && length(var.external_dns) == 0 && length(var.hosted_zone) > 0 ? 1 : 0
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  count           = var.enable_acme_cert == true && length(var.external_dns) == 0 && length(var.hosted_zone) > 0 ? 1 : 0
  account_key_pem = tls_private_key.account_key.0.private_key_pem
  email_address   = "support@bluesentryit.com"
}

resource "tls_private_key" "cert_key" {
  count     = var.enable_acme_cert == true && length(var.external_dns) == 0 && length(var.hosted_zone) > 0 ? 1 : 0
  algorithm = "RSA"
}

resource "tls_cert_request" "request" {
  count           = var.enable_acme_cert == true && length(var.external_dns) == 0 && length(var.hosted_zone) > 0 ? 1 : 0
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.cert_key.0.private_key_pem
  dns_names       = [join("", [var.dns_server_name, ".", replace(data.aws_route53_zone.subdomain.0.name, "/[.]$/", "")])]

  subject {
    common_name = join("", [var.dns_server_name, ".", replace(data.aws_route53_zone.subdomain.0.name, "/[.]$/", "")])
  }
}

resource "acme_certificate" "cert" {
  count                     = var.enable_acme_cert == true && length(var.external_dns) == 0 && length(var.hosted_zone) > 0 ? 1 : 0
  account_key_pem           = acme_registration.reg.0.account_key_pem
  certificate_request_pem   = tls_cert_request.request.0.cert_request_pem

  dns_challenge {
    provider = "route53"
  }
}
