terraform {
  backend "pg" {}
}

module "core" {
  source = "../../../modules/core"
  defaults = var.defaults
  cloudflare_api_token = var.cloudflare_api_token
}

output "core" {
  value = module.core.core
}

variable "backend_config_conn_str" {}
