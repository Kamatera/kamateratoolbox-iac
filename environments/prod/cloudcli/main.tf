terraform {
  backend "pg" {}
}

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "cloudcli-prod"
}

variable "root_domain" {}
variable "sub_domain" {}
variable "ingress_hostname" {}
