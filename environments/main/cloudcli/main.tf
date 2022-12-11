terraform {
  backend "pg" {}
}

module "cloudcli" {
  source = "../../../modules/cloudcli"
  defaults = var.defaults
  core_json = jsonencode(data.terraform_remote_state.core.outputs.core)
  cloudflare_api_token = var.cloudflare_api_token
}

variable "backend_config_conn_str" {}

data "terraform_remote_state" "core" {
  backend = "pg"
  config = {
    conn_str = var.backend_config_conn_str
    schema_name = "main_core"
  }
}
