terraform {
  required_providers {
    kamatera = {
      source = "Kamatera/kamatera"
    }
    rancher2 = {
      source = "rancher/rancher2"
    }
  }
}

provider "rancher2" {
  api_url = local.rancher_url
}
