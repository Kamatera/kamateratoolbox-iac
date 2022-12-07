terraform {}

module "apps" {
  source = "../../../modules/apps"
  defaults = var.defaults
  cloudcli_json = jsonencode(data.terraform_remote_state.cloudcli.outputs.cloudcli)
}

output "apps" {
  value = module.apps.apps
}

data "terraform_remote_state" "cloudcli" {
  backend = "local"
  config = {
    path = "${path.cwd}/environments/main/cloudcli/terraform.tfstate"
  }
}
