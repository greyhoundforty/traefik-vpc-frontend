terraform {
  backend "consul" {
    scheme = "http"
    path   = "terraform/state/vpc-traefik-lab-terraform.tfstate"
  }
}