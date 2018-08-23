# tf-module.openvpn
Terraform module for role out of an OpenVPN server

##Usage



##Argument Reference
The following module level arguments are supported.

* vpc_id - (Required) The id of the specific VPC that the OpenVPN server should be placed.

* key_name - (Required) The keypair name to be associated with the OpenVPN EC2 instance.
 
* user_count - (Required) The desired # of concurrent users to license the server for.  Any of the following are supported: 2, 5,10, 25,50,100, 250

* admin_name - (Optional)  The admin user name.  Defaults to `vpnadmin`.

* admin_password - (Required) The initial admin user password.  **NOTE**: This should only be used for the initial access to administration settings.  Password should then be promptly changed.

* name - (Optional) The name of the service.  Defaults to `OpenVPN`.

* instance_type - (Optional) The type of the instance.  Defaults to `t2.micro`.

* tags - (Optional) The tags assigned to all related resources that can be tagged.


##Attributes Reference
The following attributes are exposed.

* public_ip - The public IP address associated with the instance.

* security_group - The security group for the instance
