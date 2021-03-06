resource "local_file" "ansible-inventory" {
  content = templatefile("${path.module}/Templates/inventory.tmpl",
    {
      instances = var.instances
      bastion   = var.bastion
    }
  )
  filename = "${path.module}/inventory"
}

resource "local_file" "ansible-config" {
  content = templatefile("${path.module}/Templates/ansible.cfg.tmpl",
    {
      bastion = var.bastion
    }
  )
  filename = "${path.module}/ansible.cfg"
}

resource "local_file" "ansible-vars" {
  content = templatefile("${path.module}/Templates/vars.tmpl",
    {
      encrypt_key          = var.encrypt_key
      region               = var.region
      logdna_ingestion_key = var.logdna_ingestion_key
    }
  )
  filename = "${path.module}/Playbooks/vars.yml"
}

resource "local_file" "consul-traefik-config" {
  content = templatefile("${path.module}/Templates/consul.tmpl",
    {
      instances    = var.instances
      consul_name  = var.consul_name
      traefik_name = var.traefik_name
    }
  )
  filename = "${path.module}/Templates/dynamic/consul.yaml"
}

resource "local_file" "api-traefik-config" {
  content = templatefile("${path.module}/Templates/api.tmpl",
    {
      traefik_name = var.traefik_name
    }
  )
  filename = "${path.module}/Templates/dynamic/api.toml"
}

resource "local_file" "ssh-key" {
  content         = var.private_key_pem
  filename        = "${path.module}/generated_key_rsa"
  file_permission = "0600"
}