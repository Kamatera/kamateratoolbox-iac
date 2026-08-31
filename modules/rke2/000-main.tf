terraform {
  required_providers {
    kamatera = {
      source = "Kamatera/kamatera"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}
