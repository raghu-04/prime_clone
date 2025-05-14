variable "region" {
  description = "Enter the region where the resources to be created"
}

variable "ami_id" {
  description = "Select the aws machine required"
}

variable "instance_type" {
  description = "Select the required instance type"
}

variable "key_name" {
  description = "Enter the key name"
}

variable "server_name" {
  description = "Enter the desired ec2_server name"
}

variable "volume_size" {
  description = "Enter the volume size"
}