
variable "public_subnet_ids" {
  type = "list"
}


variable "admin_user" {}

variable "admin_password" {}


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

variable "tags" {
  description = "The tags assigned to all related resources that can be tagged"
  type        = "map"
}

variable "user_count" {
  description = "User license count"
}

variable "user_license" {
  type = "map"
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

variable "vpc_cidr" {
  description = "CIDR block that will have access to openvpn server"
}

variable "vpc_id" {
  description = "VPC id where openvpn server will be placed"
}