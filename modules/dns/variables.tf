variable "defaults" {
  type = map(string)
}

variable "cloudcli_json" {}

locals {
  cloudcli = jsondecode(var.cloudcli_json)
}

variable "cloudflare_api_token" {
  sensitive = true
}
