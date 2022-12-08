terraform {
  backend "pg" {}
}

module "storage" {
  source = "../../../modules/storage"
  defaults = var.defaults
  cloudcli_json = jsonencode(data.terraform_remote_state.cloudcli.outputs.cloudcli)
}

output "storage" {
  value = module.storage.storage
}

variable "backend_config_conn_str" {}

data "terraform_remote_state" "cloudcli" {
  backend = "pg"
  config = {
    conn_str = var.backend_config_conn_str
    schema_name = "main_cloudcli"
  }
}
