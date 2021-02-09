resource "ibm_is_security_group" "maintenance_security_group" {
  name           = "${var.name}-maintenance-security-group"
  vpc            = var.vpc_id
  resource_group = var.resource_group
}

resource "ibm_is_security_group_rule" "maintenance_ssh_in" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "maintenance_http_in" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "maintenance_https_in" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "maintenance_all_open_dmz" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "inbound"
  remote    = var.subnet_cidr
}

resource "ibm_is_security_group_rule" "maintenance_allow_outbound" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group" "services_security_group" {
  name           = "${var.name}-services-security-group"
  vpc            = var.vpc_id
  resource_group = var.resource_group
}

resource "ibm_is_security_group_rule" "services_all_open_dmz" {
  group     = ibm_is_security_group.services_security_group.id
  direction = "inbound"
  remote    = var.subnet_cidr
}

resource "ibm_is_security_group_rule" "consul_allow_outbound" {
  group     = ibm_is_security_group.services_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}