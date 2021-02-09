resource "digitalocean_record" "traefik" {
  domain = var.domain
  type   = "A"
  name   = var.traefik_instance.name
  value  = var.traefik_address
}

resource "digitalocean_record" "consul" {
  domain = var.domain
  type   = "A"
  name   = var.consul_name
  value  = var.traefik_address
}

resource "ibm_resource_instance" "project_instance" {
  name              = "${var.name}-dns-instance"
  resource_group_id = var.resource_group
  location          = "global"
  service           = "dns-svcs"
  plan              = "standard-dns"
}

resource "ibm_dns_zone" "zone" {
  name        = var.domain
  instance_id = ibm_resource_instance.project_instance.guid
  description = "Private DNS Zone for VPC DNS communication."
  label       = "split-dns-test"
}

resource "ibm_dns_permitted_network" "permitted_network" {
  instance_id = ibm_resource_instance.project_instance.guid
  zone_id     = ibm_dns_zone.zone.zone_id
  vpc_crn     = var.vpc_crn
  type        = "vpc"
}

resource "ibm_dns_resource_record" "consul_records" {
  count       = length(var.consul_instances[*].name)
  instance_id = ibm_resource_instance.project_instance.guid
  zone_id     = ibm_dns_zone.zone.zone_id
  type        = "A"
  name        = element(var.consul_instances[*].name, count.index)
  rdata       = element(var.consul_instances[*].primary_network_interface[0].primary_ipv4_address, count.index)
  ttl         = 3600
}

resource "ibm_dns_resource_record" "traefik_records" {
  instance_id = ibm_resource_instance.project_instance.guid
  zone_id     = ibm_dns_zone.zone.zone_id
  type        = "A"
  name        = var.traefik_instance.name
  rdata       = var.traefik_instance.primary_network_interface[0].primary_ipv4_address
  ttl         = 3600
}
