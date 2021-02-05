output maintenance_group {
  value = ibm_is_security_group.maintenance_security_group.id
}

output consul_group {
  value = ibm_is_security_group.consul_security_group.id
}