variable "defaults" {
  type = map(string)
}

variable "cloudcli_json" {}

locals {
  cloudcli = jsondecode(var.cloudcli_json)
}
