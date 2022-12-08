terraform {
  backend "pg" {}
}

module "apps" {
  source = "../../../modules/apps"
  defaults = var.defaults
  cloudcli_json = jsonencode(data.terraform_remote_state.cloudcli.outputs.cloudcli)
}

output "apps" {
  value = module.apps.apps
}

variable "backend_config_conn_str" {}

data "terraform_remote_state" "cloudcli" {
  backend = "pg"
  config = {
    conn_str = var.backend_config_conn_str
    schema_name = "main_cloudcli"
  }
}
