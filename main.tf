resource tls_private_key ssh {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource ibm_is_ssh_key generated_key {
  name           = "${var.name}-${var.region}-sshkey"
  public_key     = tls_private_key.ssh.public_key_openssh
  resource_group = data.ibm_resource_group.project.id
  tags           = concat(var.tags, ["region:${var.region}", "project:${var.name}"])
}

locals {
  domain = "${var.name}-${var.region}.lab"
}

module vpc {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Module.git"
  name           = "${var.name}-vpc"
  resource_group = data.ibm_resource_group.project.id
  tags           = ["project:${var.name}", "region:${var.region}"]
}

module public_gateway {
  source            = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Public-Gateway-Module.git"
  name              = "${var.name}-public-gateway"
  zone              = data.ibm_is_zones.region.zones[1]
  vpc_id            = module.vpc.id
  resource_group_id = data.ibm_resource_group.project.id
  tags              = concat(var.tags, ["project:${var.name}", "region:${var.region}", "zone:${data.ibm_is_zones.region.zones[1]}"])
}

module subnet {
  source         = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Subnet-Module.git"
  name           = "${var.name}-subnet"
  resource_group = data.ibm_resource_group.project.id
  network_acl    = module.vpc.default_network_acl
  address_count  = "128"
  vpc            = module.vpc.id
  zone           = data.ibm_is_zones.region.zones[1]
  public_gateway = module.public_gateway.id
}

module security {
  source         = "./security"
  name           = var.name
  subnet_cidr    = module.subnet.ipv4_cidr_block
  resource_group = data.ibm_resource_group.project.id
  remote_address = var.remote_address
  vpc_id         = module.vpc.id
}

module traefik {
  source            = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Instance-Module.git"
  name              = "${var.name}-traefik-instance"
  vpc_id            = module.vpc.id
  subnet_id         = module.subnet.id
  ssh_keys          = [ibm_is_ssh_key.generated_key.id]
  resource_group    = data.ibm_resource_group.project.id
  zone              = data.ibm_is_zones.region.zones[1]
  security_group_id = module.security.maintenance_group
  tags              = concat(var.tags, ["project:${var.name}", "region:${var.region}", "zone:${data.ibm_is_zones.region.zones[1]}"])
  user_data         = templatefile("${path.module}/install.yml", { domain = local.domain, generated_key = tls_private_key.ssh.public_key_openssh })
}

resource ibm_is_floating_ip traefik {
  name           = "${var.name}-traefik-fip"
  target         = module.traefik.primary_network_interface_id
  resource_group = data.ibm_resource_group.project.id
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "zone:${data.ibm_is_zones.region.zones[1]}"])
}

module consul {
  source            = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Instance-Module.git"
  count             = 3
  name              = "${var.name}-consul-instance-${count.index + 1}"
  vpc_id            = module.vpc.id
  subnet_id         = module.subnet.id
  ssh_keys          = [ibm_is_ssh_key.generated_key.id]
  resource_group    = data.ibm_resource_group.project.id
  zone              = data.ibm_is_zones.region.zones[1]
  security_group_id = module.security.consul_group
  tags              = concat(var.tags, ["project:${var.name}", "region:${var.region}", "zone:${data.ibm_is_zones.region.zones[1]}"])
  user_data         = templatefile("${path.module}/install.yml", { domain = local.domain, generated_key = tls_private_key.ssh.public_key_openssh })
}

module dns {
  source = "./dns"
}

module ansible {
  source          = "./ansible"
  instances       = module.consul[*].instance
  bastion         = ibm_is_floating_ip.traefik.address
  private_key_pem = tls_private_key.ssh.private_key_pem
  encrypt_key     = var.encrypt_key
  region          = var.region
}