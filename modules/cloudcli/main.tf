variable "cloudflare_api_token" {}
variable "defaults" {type = map(string)}
variable "core_json" {}

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  core = jsondecode(var.core_json)
}
