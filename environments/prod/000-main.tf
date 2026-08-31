terraform {
  backend "pg" {}

  required_providers {
    kamatera = {
      source = "Kamatera/kamatera"
      version = "0.9.4"
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
      version = "5.22.0"
    }
    statuscake = {
      source = "StatusCakeDev/statuscake"
    }
  }
}

provider "kamatera" {
  api_client_id = var.kamatera_api_client_id
  api_secret = var.kamatera_api_secret
}

provider "statuscake" {
  api_token = var.statuscake_api_token
}
