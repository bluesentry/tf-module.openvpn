# tf-module.openvpn
Terraform module for role out of an OpenVPN server

## Usage
```hcl-terraform
module "openvpn" {
  source            = "git@github.com:bluesentry/tf-module.openvpn.git?ref=v2.0.0"
  vpc_id            = module.vpc.vpc_id
  subnet_id         = element(module.vpc.public_subnets, 0)
  instance_profile  = module.backup.backup_role_name
  key_name          = module.key-openvpn.key_name
  ssh_private_key   = module.key-openvpn.private_key
  instance_type     = "t2.micro"
  admin_user        = "vpnadmin"
  user_count        = 2
  tags              = local.tags
}
```

## Terraform versions ##
Terraform 0.12. Pin module version to ~> v2.0. Code changes are handled in `master` branch

Terraform 0.11. Pin module version to ~> v1.0. Code changes are handled in `v11` branch

## Running Terraform
If it is the first install on an account; you will likely see an error like this when running terraform.  Follow the link and subscribe to the AWS marketplace license, then re-run terraform.
```
* aws_instance.openvpn: Error launching source instance: OptInRequired: In order to use this AWS 
Marketplace product you need to accept terms and subscribe. To do so 
please visit https://aws.amazon.com/marketplace/pp?sku=blahblahsomething
```

## SSL
The OpenVPN server requires an ssl cert and does not currently support being put behind a load balancer.  Currently this module will generate an acme certificate via `Letsencrypt` by default and install it on the server.  This can be disabled using `enable_acme_cert`.  Note that Acme certs are free but require renewal every 90 days.  The renewal is managed by this terraform also, just rerun plan when time to renew and apply.


## Argument Reference
The following module level arguments are supported.

* **vpc_id** - (Required) The id of the specific VPC that the OpenVPN server should be placed.

* **key_name** - (Required) The keypair name to be associated with the OpenVPN EC2 instance.
 
* **ssh_private_key** - (Required) Private key used to ssh into server and configure.

* **subnet_id** - (Required) Subnet where openvpn instance will be placed.

* **user_count** - (Required) The desired # of concurrent users to license the server for.  Any of the following are supported: 2, 5,10, 25,50,100, 250

* **admin_password** - (Optional) The initial admin user password.  **NOTE**: Generally a bad idea.  Better to leave blank and let password be auto-generated.

* **admin_password_secretkey** - (optional) If using an already existing secret, provide name here (if left blank a new secret will be generated)

* **admin_name** - (Optional) The admin user name.  Defaults to `vpnadmin`.

* **dns_server_name** - (Optional) DNS server name to be added to domain.  Default is vpn. i.e. `vpn.example.com`

* **enable_acme_cert** - (optional) When set to true, a free acme cert will be generated and configured.  Can NOT be used with `external_dns` Default is `true`

* **external_dns** - (optional) Externally managed DNS can be provided.  Leaving blank will cause use of Route53 if hosted_zone provided

* **name** - (Optional) The name of the service.  Defaults to `OpenVPN`.

* **hosted_zone** - (Optional) The Route 53 hosted zone id.  If provided, an entry will be added for vpn.{zone domain}.

* **instance_type** - (Optional) The type of the instance.  Defaults to `t2.micro`.

* **private_zones** - (Optional) If provided, DNS for these zones will be routed through VPN

* **tags** - (Optional) The tags assigned to all related resources that can be tagged.


## Attributes Reference
The following attributes are exposed.

* **public_ip** - The public IP address associated with the instance.

* **security_group** - The security group for the instance


## Notes

SSH - doubtful that you would need to SSH into the openvpn server, but if you do. note that use openvpnas instead of ec2-user

```bash
aws-sudo client aws secretsmanager get-secret-value --secret-id openvpn.pem | jq -r '.SecretString' > ~/keys/client-openvpn.pem
chmod 600 ~/keys/client-openvpn.pem
ssh -i ~/keys/client-openvpn.pem openvpnas@<EIP-or-DNS>
```

## Configuration Examples

* Auto generated admin password, no DNS configuration, no certs.  VPN will be accessed via public IP

```hcl-terraform
module "key-openvpn" {
  source  = "git@github.com:bluesentry/tf-module.keypair.git?ref=v2.0.3"
  name    = "test-openvpn"
  tags    = local.tags
}
module "openvpn" {
  source            = "git@github.com:bluesentry/tf-module.openvpn.git?ref=v2.0.0"
  name              = "openvpn"
  admin_user        = "vpnadmin"
  instance_type     = "t2.micro"
  key_name          = module.key-openvpn.key_name
  subnet_id         = element(module.vpc.public_subnets, 0)
  ssh_private_key   = module.key-openvpn.private_key
  tags              = local.tags
  user_count        = 2
  vpc_id            = module.vpc.vpc_id
}
```

* Static admin password for quick test (Don't leave it like this with password exposed!)
```hcl-terraform
module "openvpn" {
  source            = "git@github.com:bluesentry/tf-module.openvpn.git?ref=v2.0.0"
  name              = "openvpn"
  instance_type     = "t2.micro"
  key_name          = module.key-openvpn.key_name
  subnet_id         = element(module.vpc.public_subnets, 0)
  ssh_private_key   = module.key-openvpn.private_key
  tags              = local.tags
  user_count        = 2
  vpc_id            = module.vpc.vpc_id

  admin_user        = "vpnadmin"
  admin_password    = "9DWX8q9GghwvFb34Nbpn"
}
```

* Existing admin password already stored in Secrets Manager, Pass in the secret key name
```hcl-terraform
module "openvpn" {
  source            = "git@github.com:bluesentry/tf-module.openvpn.git?ref=v2.0.0"
  name              = "openvpn"
  instance_type     = "t2.micro"
  key_name          = module.key-openvpn.key_name
  subnet_id         = element(module.vpc.public_subnets, 0)
  ssh_private_key   = module.key-openvpn.private_key
  tags              = local.tags
  user_count        = 2
  vpc_id            = module.vpc.vpc_id

  admin_user               = "vpnadmin"
  admin_password_secretkey = "some_secret_key"
}
```

* Set DNS endpoint to `abc.somedomain.net` via Route53, but attach no cert. You will have to configure the certificate manually via the admin console.
```hcl-terraform
module "openvpn" {
  source            = "git@github.com:bluesentry/tf-module.openvpn.git?ref=v2.0.0"
  name              = "openvpn"
  admin_user        = "vpnadmin"
  instance_type     = "t2.micro"
  key_name          = module.key-openvpn.key_name
  subnet_id         = element(module.vpc.public_subnets, 0)
  ssh_private_key   = module.key-openvpn.private_key
  tags              = local.tags
  user_count        = 2
  vpc_id            = module.vpc.vpc_id

  hosted_zone       = var.hosted_zone
  dns_server_name   = "abc"
  enable_acme_cert  = false
}
```

* Set DNS endpoint to `vpn.somedomain.net` via Route53 this is default value of `dns_server_name`, and attach an acme cert since true is default value of `enable_acme_cert`
```hcl-terraform
module "openvpn" {
  source            = "git@github.com:bluesentry/tf-module.openvpn.git?ref=v2.0.0"
  name              = "openvpn"
  admin_user        = "vpnadmin"
  instance_type     = "t2.micro"
  key_name          = module.key-openvpn.key_name
  subnet_id         = element(module.vpc.public_subnets, 0)
  ssh_private_key   = module.key-openvpn.private_key
  tags              = local.tags
  user_count        = 2
  vpc_id            = module.vpc.vpc_id

  hosted_zone       = var.hosted_zone
}
```