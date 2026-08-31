terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
    }
    statuscake = {
      source = "StatusCakeDev/statuscake"
    }
  }
}

provider "kubernetes" {
  config_path = var.admin_kubeconfig_path
}
