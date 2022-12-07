terraform {}

module "dns" {
  source = "../../../modules/dns"
  defaults = var.defaults
  cloudcli_json = jsonencode(data.terraform_remote_state.cloudcli.outputs.cloudcli)
  cloudflare_api_token = var.cloudflare_api_token
}

output "dns" {
  value = module.dns.dns
}

data "terraform_remote_state" "cloudcli" {
  backend = "local"
  config = {
    path = "${path.cwd}/environments/main/cloudcli/terraform.tfstate"
  }
}
