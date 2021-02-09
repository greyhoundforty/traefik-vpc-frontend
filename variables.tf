variable "region" {
  type        = string
  description = "The region where the VPC resources will be deployed."
  default     = ""
}

variable "resource_group" {
  type        = string
  description = "Resource group where resources will be deployed."
  default     = ""
}

variable "name" {
  type        = string
  description = ""
  default     = ""
}


variable tags {
  default = ["owner:ryantiffany", "terraform"]
}

variable encrypt_key {}
#variable ibmcloud_api_key {}
variable remote_address {
  default = "0.0.0.0"
}
variable logdna_ingestion_key {}
variable domain {}
