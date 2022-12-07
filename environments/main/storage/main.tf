terraform {}

module "storage" {
  source = "../../../modules/storage"
  defaults = var.defaults
  cloudcli_json = jsonencode(data.terraform_remote_state.cloudcli.outputs.cloudcli)
}

output "storage" {
  value = module.storage.storage
}

data "terraform_remote_state" "cloudcli" {
  backend = "local"
  config = {
    path = "${path.cwd}/environments/main/cloudcli/terraform.tfstate"
  }
}
