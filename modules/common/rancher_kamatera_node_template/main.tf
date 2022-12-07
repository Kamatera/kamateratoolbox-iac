variable "rancher_url" {}
variable "name" {}
variable "billing" {}
variable "cpu" {}
variable "datacenter" {}
variable "diskSize" {}
variable "extraDiskSizes" {}
variable "extraSshkey" {}
variable "image" {}
variable "privateNetworkIp" {}
variable "privateNetworkName" {}
variable "ram" {}
variable "trigger" {default = ""}

locals {
  config = {
    billing = var.billing
    cpu = var.cpu
    datacenter = var.datacenter
    diskSize = var.diskSize
    extraDiskSizes = var.extraDiskSizes
    extraSshkey = var.extraSshkey
    image = var.image
    privateNetworkIp = var.privateNetworkIp
    privateNetworkName = var.privateNetworkName
    ram = var.ram
  }
  command = <<-EOF
    python3 create_node_template.py \
      ${var.rancher_url} \
      ${var.name} \
      '${jsonencode(local.config)}'
  EOF
}

resource "null_resource" "create_node_template" {
  triggers = {
    command = local.command
    md5 = filemd5("${path.module}/create_node_template.py")
    trigger = var.trigger
  }
  provisioner "local-exec" {
    command = <<-EOF
      cd ${path.module}
      ${local.command}
    EOF
  }
}

output "name" {
  value = var.name
}
