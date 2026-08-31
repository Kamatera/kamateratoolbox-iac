terraform {
  required_providers {
    kamatera = {
      source = "Kamatera/kamatera"
    }
  }
}

variable "datacenter_id" {}
variable "name" {}
variable "subnet_ip" {
  default = "172.16.0.0"
}
variable "subnet_bit" {
  type = number
  default = 23
}

resource "kamatera_network" "private" {
  datacenter_id = var.datacenter_id
  name = var.name
  subnet {
    ip = var.subnet_ip
    bit = var.subnet_bit
  }
}

output "full_name" {
  value = kamatera_network.private.full_name
}
output "cidr" {
  value = "${var.subnet_ip}/${var.subnet_bit}"
}
