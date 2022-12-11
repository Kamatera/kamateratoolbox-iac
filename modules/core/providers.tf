terraform {
  required_providers {
    kamatera = {
      source = "Kamatera/kamatera"
    }
    rancher2 = {
      source = "rancher/rancher2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
    }
  }
}

provider "rancher2" {
  api_url = "https://${cloudflare_record.rancher.hostname}"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "cloudcli"
}
