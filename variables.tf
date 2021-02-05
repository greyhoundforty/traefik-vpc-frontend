variable "region" {
  type        = string
  description = "The region where the VPC resources will be deployed."
  default     = "au-syd"
}

variable "resource_group" {
  type        = string
  description = "Resource group where resources will be deployed."
  default     = "CDE"
}

variable "name" {
  type        = string
  description = ""
  default     = "rtlab"
}

variable remote_address {
  default = "76.31.10.241"
}

variable tags {
  default = ["owner:ryantiffany", "terraform"]
}

variable encrypt_key {}