
variable "admin_user" {
  description = "(optional) The admin user name.  Default is 'vpnadmin'"
  default     = "vpnadmin"
}

variable "admin_password" {
  description = "(optional and Not Recommmended!) password for Admin user (if left blank will use provided secret key or random generated)"
  default     = ""
}

variable "admin_password_secretkey" {
  description = "(optional) If using an already existing secret, provide name here (if left blank a new secret will be generated)"
  default     = ""
}

variable "dns_server_name" {
  description = "(optional) DNS server name to be added to domain, if `hosted_zone` is provided.  Default is vpn, which will result in similiar `vpn.example.com`"
  default     = "vpn"
}

variable "enable_acme_cert" {
  description = "(optional) If set to true, a free acme cert will be generated and configured.  Can NOT be used with `external_dns`"
  type        = bool
  default     = true
}

variable "external_dns" {
  description = "(optional) Externally managed DNS can be provided.  Leaving blank will cause use of Route53 if hosted_zone provided"
  default     = ""
}

variable "hosted_zone" {
  description = "(optional) R53 hosted zone id, if provided an entry will be added for the openvpn server"
  default     = ""
}

variable "instance_profile" {
  description = "(optional) Role for IAM instance profile"
  default = ""
}

variable "instance_type" {
  default     = "t2.micro"
}

variable "key_name" {
  description = "Key pair name to access openvpn EC2 instance"
}

variable "name" {
  default = "openvpn"
}

variable "private_zones" {
  description = "comma delimited list of private r53 zones, that dns should be routed thru vpn"
  default     = ""
}

variable "ssh_private_key" {
  description = "private key (pem) file contents"
}

variable "subnet_id" {
  description = "subnet where openvpn instance will be placed"
  type        = string
}

variable "tags" {
  description = "The tags assigned to all related resources that can be tagged"
  type        = map(string)
}

variable "user_count" {
  description = "User license count"
}

variable "user_license" {
  type = map(string)
  description = "Maps to OpenVPN Access Server Product IDs"

  default = {
    "2"   = "fe8020db-5343-4c43-9e65-5ed4a825c931"
    "5"   = "3b5882c4-551b-43fa-acfe-7f5cdb896ff1"
    "10"  = "8fbe3379-63b6-43e8-87bd-0e93fd7be8f3"
    "25"  = "23223b90-d61f-472a-b732-f2b98e6fa3fb"
    "50"  = "bbff26cd-b407-44a2-a7ef-70b8971391f1"
    "100" = "7091ef09-bad5-4f1d-9596-0ddf93d97793"
    "250" = "aac3a8a3-2823-483c-b5aa-60022894b89d"
  }
}

variable "vpc_id" {
  description = "VPC id where openvpn server will be placed"
}

