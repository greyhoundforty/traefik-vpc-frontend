terraform {
  required_version = ">= 0.13.2"

  required_providers {
    ibm = {
      source           = "IBM-Cloud/ibm"
      required_version = ">= 1.13"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.5.1"
    }
  }
}