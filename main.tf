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
  name           = "${var.name}-maintenance-subnet"
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

module flowlogs {
  source         = "./flowlogs"
  name           = var.name
  resource_group = data.ibm_resource_group.project.id
  vpc_id         = module.vpc.id
  region         = var.region
  subnet         = module.subnet.id
  tags           = concat(var.tags, ["project:${var.name}", "region:${var.region}", "zone:${data.ibm_is_zones.region.zones[1]}"])
}

module traefik {
  source            = "git::https://github.com/cloud-design-dev/IBM-Cloud-VPC-Instance-Module.git"
  name              = "${var.name}-traefik"
  vpc_id            = module.vpc.id
  subnet_id         = module.subnet.id
  ssh_keys          = [ibm_is_ssh_key.generated_key.id]
  resource_group    = data.ibm_resource_group.project.id
  zone              = data.ibm_is_zones.region.zones[1]
  security_group_id = module.security.maintenance_group
  tags              = concat(var.tags, ["project:${var.name}", "region:${var.region}", "zone:${data.ibm_is_zones.region.zones[1]}"])
  user_data         = templatefile("${path.module}/install.yml", { domain = data.digitalocean_domain.project.name, generated_key = tls_private_key.ssh.public_key_openssh })
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
  name              = "${var.name}-consul-${count.index + 1}"
  vpc_id            = module.vpc.id
  subnet_id         = module.subnet.id
  ssh_keys          = [ibm_is_ssh_key.generated_key.id]
  resource_group    = data.ibm_resource_group.project.id
  zone              = data.ibm_is_zones.region.zones[1]
  security_group_id = module.security.services_group
  tags              = concat(var.tags, ["project:${var.name}", "region:${var.region}", "zone:${data.ibm_is_zones.region.zones[1]}"])
  user_data         = templatefile("${path.module}/install.yml", { domain = data.digitalocean_domain.project.name, generated_key = tls_private_key.ssh.public_key_openssh })
}

module dns {
  source           = "./dns"
  name             = var.name
  domain           = data.digitalocean_domain.project.name
  traefik_address  = ibm_is_floating_ip.traefik.address
  consul_name      = "${var.name}-consul"
  traefik_instance = module.traefik.instance
  consul_instances = module.consul[*].instance
  vpc_crn          = module.vpc.crn
  resource_group   = data.ibm_resource_group.project.id
}

module ansible {
  source               = "./ansible"
  instances            = module.consul[*].instance
  consul_name          = "${var.name}-consul"
  traefik_name         = "${var.name}-traefik"
  bastion              = ibm_is_floating_ip.traefik.address
  private_key_pem      = tls_private_key.ssh.private_key_pem
  encrypt_key          = var.encrypt_key
  region               = var.region
  logdna_ingestion_key = var.logdna_ingestion_key
}

# resource null_resource remove_traefik_address {
#   provisioner local-exec {
#     command = "ssh-keygen -f ~/.ssh/known_hosts -R ${ibm_is_floating_ip.traefik.address}"
#   }
# }

# resource null_resource remove_internal_addresses {
#   count = length(module.consul[*].primary_ip4_address)
#   provisioner local-exec {
#     command = "ssh-keygen -f ~/.ssh/known_hosts -R ${module.consul[count.index].primary_ip4_address}"
#   }
# }