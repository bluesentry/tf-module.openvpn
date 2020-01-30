
# Add secret for storing admin password
resource "aws_secretsmanager_secret" "vpnadmin" {
  count       = length(var.admin_password_secretkey) == 0 ? 1 : 0
  name        = "${var.name}-${var.admin_user}-${random_string.name.0.result}"
  description = "Password for openvpn admin user (${var.admin_user})"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "vpnadmin" {
  count         = length(var.admin_password_secretkey) == 0 ? 1 : 0
  secret_id     = aws_secretsmanager_secret.vpnadmin.0.id
  secret_string = length(var.admin_password) == 0 ? random_string.password.0.result : var.admin_password
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "random_string" "password" {
  count   = length(var.admin_password_secretkey) == 0 && length(var.admin_password) == 0 ? 1 : 0
  length  = 16
  special = false
}

# Random characters added to secret name, making it unique and allowing plan -destory and recreate, since secrets are not deleted right away
resource "random_string" "name" {
  count   = length(var.admin_password_secretkey) == 0 ? 1 : 0
  length  = 4
  special = false
}

data "aws_secretsmanager_secret" "provided-pwd" {
  count     = length(var.admin_password_secretkey) > 0 ? 1 : 0
  name      = var.admin_password_secretkey
}
data "aws_secretsmanager_secret_version" "provided-pwd" {
  count     = length(var.admin_password_secretkey) > 0 ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.provided-pwd.0.id
}