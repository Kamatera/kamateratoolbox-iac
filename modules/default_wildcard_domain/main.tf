terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
    }
    rancher2 = {
      source  = "rancher/rancher2"
    }
    statuscake = {
      source = "StatusCakeDev/statuscake"
    }
  }
}

provider "rancher2" {
  api_url = "https://${var.rancher_a_record_name}.${var.root_domain}"
}

variable "root_domain" {}
variable "letsencrypt_email" {}
variable "nfs_private_ip" {}
variable "rancher_public_ip" {}
variable "ssh_private_key_file" {}
variable "rancher_a_record_name" {default = ""}

locals {
  # Build from docker/certbot on Dec 11, 2022
  certbot_image = "ghcr.io/kamatera/kamateratoolbox-iac-certbot:c9b1c1c39f685b662bddfab69b9ce6b976f52b58"
}

resource "null_resource" "certbot" {
  triggers   = {
    command = <<-EOF
      python3 certbot.py "${var.root_domain}" "${var.letsencrypt_email}" \
        "${local.certbot_image}" \
        "${var.nfs_private_ip}" \
        "${var.rancher_public_ip}" \
        "../../${var.ssh_private_key_file}"
    EOF
    md5 = filemd5("${path.module}/certbot.py")
  }
  provisioner "local-exec" {
    command = <<EOF
      cd ${path.module} &&\
      ${self.triggers.command}
    EOF
  }
}

data "cloudflare_zone" "default" {
  name = var.root_domain
}

resource "cloudflare_record" "rancher" {
  count = var.rancher_a_record_name == "" ? 0 : 1
  zone_id = data.cloudflare_zone.default.id
  name = var.rancher_a_record_name
  type = "A"
  value = var.rancher_public_ip
  proxied = false
}

resource "rancher2_setting" "server_url" {
  count = var.rancher_a_record_name == "" ? 0 : 1
  name = "server-url"
  value = "https://${var.rancher_a_record_name}.${var.root_domain}"
}

output "rancher_url" {
  value = "https://${var.rancher_a_record_name}.${var.root_domain}"
}
