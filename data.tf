
data "ibm_resource_group" "project" {
  name = var.resource_group
}

data "ibm_is_zones" "region" {
  region = var.region
}

data "digitalocean_domain" "project" {
  name = var.domain
}
