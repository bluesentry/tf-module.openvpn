# tf-module.openvpn
Terraform module for role out of an OpenVPN server

## Usage
```hcl-terraform
module "openvpn" {
  source            = "git@github.com:bluesentry/tf-module.openvpn.git?ref=v1.0.9"
  vpc_id            = "${module.vpc.vpc_id}"
  public_subnet_ids = "${module.vpc.public_subnets}"
  instance_profile  = "${module.backup.backup_role_name}"
  key_name          = "${module.key-openvpn.key_name}"
  ssh_private_key   = "${module.key-openvpn.private_key}"
  instance_type     = "t2.micro"
  admin_user        = "vpnadmin"
  admin_password    = "9DWX8q9GghwvFb34Nbpn"
  user_count        = 2
  tags              = "${local.tags}"
}
```

## Running Terraform
If it is the first install on an account; you will likely see an error like this when running terraform.  Follow the link and subscribe to the AWS marketplace license, then re-run terraform.
```
* aws_instance.openvpn: Error launching source instance: OptInRequired: In order to use this AWS 
Marketplace product you need to accept terms and subscribe. To do so 
please visit https://aws.amazon.com/marketplace/pp?sku=blahblahsomething
```

## SSL
The OpenVPN server requires an ssl cert and does not currently support being put behind a load balancer.  Currently this module will generate an acme certificate via `Letsencrypt` and install it on the server.
**Note:** The cert will only be created if hosted_zone is provided a value.  If left blank, the openvpn server will be created, but with no cert installed.

## Argument Reference
The following module level arguments are supported.

* **vpc_id** - (Required) The id of the specific VPC that the OpenVPN server should be placed.

* **key_name** - (Required) The keypair name to be associated with the OpenVPN EC2 instance.
 
* **ssh_private_key** - (Required) Private key used to ssh into server and configure.

* **user_count** - (Required) The desired # of concurrent users to license the server for.  Any of the following are supported: 2, 5,10, 25,50,100, 250

* **admin_password** - (Required) The initial admin user password.  **NOTE**: This should only be used for the initial access to administration settings.  Password should then be promptly changed.

* **admin_name** - (Optional) The admin user name.  Defaults to `vpnadmin`.

* **dns_server_name** - (Optional) DNS server name to be added to domain.  Default is vpn. i.e. `vpn.example.com`"

* **name** - (Optional) The name of the service.  Defaults to `OpenVPN`.

* **secret_name** - (Optional) Provides ability to specify the secret name used to store the admin password in Secret Manager.

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

