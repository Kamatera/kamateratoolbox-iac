terraform {
  backend "pg" {}
}

module "dns" {
  source = "../../../modules/dns"
  defaults = var.defaults
  cloudcli_json = jsonencode(data.terraform_remote_state.cloudcli.outputs.cloudcli)
  cloudflare_api_token = var.cloudflare_api_token
}

output "dns" {
  value = module.dns.dns
}

variable "backend_config_conn_str" {}

data "terraform_remote_state" "cloudcli" {
  backend = "pg"
  config = {
    conn_str = var.backend_config_conn_str
    schema_name = "main_cloudcli"
  }
}
