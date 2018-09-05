# tf-module.openvpn
Terraform module for role out of an OpenVPN server

## Usage
```hcl-terraform
module "backup" {
  source            = "git@github.com:bluesentry/tf-module.openvpn.git?ref=v1.0.1"
  vpc_id            = "${module.vpc.vpc_id}"
  vpc_cidr          = "${module.vpc.vpc_cidr_block}"
  public_subnet_ids = "${module.vpc.public_subnets}"
  instance_profile  = "${module.backup.backup_role_name}"
  key_name          = "${module.key-openvpn.key_name}"
  instance_type     = "t2.micro"
  admin_user        = "vpnadmin"
  admin_password    = "9DWX8q9GghwvFb34Nbpn"
  user_count        = 2
  tags              = "${local.tags}"
}
```


## Argument Reference
The following module level arguments are supported.

* vpc_id - (Required) The id of the specific VPC that the OpenVPN server should be placed.

* key_name - (Required) The keypair name to be associated with the OpenVPN EC2 instance.
 
* user_count - (Required) The desired # of concurrent users to license the server for.  Any of the following are supported: 2, 5,10, 25,50,100, 250

* admin_password - (Required) The initial admin user password.  **NOTE**: This should only be used for the initial access to administration settings.  Password should then be promptly changed.

* admin_name - (Optional) The admin user name.  Defaults to `vpnadmin`.

* name - (Optional) The name of the service.  Defaults to `OpenVPN`.

* hosted_zone - (Optional) The Route 53 hosted zone id.  If provided, an entry will be added for vpn.{zone domain}.

* instance_type - (Optional) The type of the instance.  Defaults to `t2.micro`.

* split_tunnel - (true/false) A VPN is considered to be a split tunnel if it only routes private traffic over the tunnel and not the traffic destined for the default gateway.  Defaults to `true`

* tags - (Optional) The tags assigned to all related resources that can be tagged.


## Attributes Reference
The following attributes are exposed.

* public_ip - The public IP address associated with the instance.

* security_group - The security group for the instance


## Notes

SSH - doubtful that you would need to SSH into the openvpn server, but if you do. note that use openvpnas instead of ec2-user

```bash
aws-sudo client aws secretsmanager get-secret-value --secret-id openvpn.pem | jq -r '.SecretString' > ~/keys/client-openvpn.pem
chmod 600 ~/keys/client-openvpn.pem
ssh -i ~/keys/client-openvpn.pem openvpnas@<EIP-or-DNS>
```

