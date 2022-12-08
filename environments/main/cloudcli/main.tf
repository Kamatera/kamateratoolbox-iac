terraform {
  backend "pg" {}
}

module "cloudcli" {
  source = "../../../modules/cloudcli"
  defaults = var.defaults
}

output "cloudcli" {
  value = module.cloudcli.cloudcli
}

output "kubeconfig" {
  value = module.cloudcli.kubeconfig
  sensitive = true
}

variable "backend_config_conn_str" {}
