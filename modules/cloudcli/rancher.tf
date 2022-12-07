data "kamatera_image" "ubuntu" {
  datacenter_id = var.defaults.datacenter_id
  os = "Ubuntu"
  code = "20.04 64bit_optimized_updated"
}

resource "kamatera_server" "rancher" {
  name = "cloudcli-rancher"
  datacenter_id = var.defaults.datacenter_id
  cpu_type = "B"
  cpu_cores = 2
  ram_mb = 4096
  disk_sizes_gb = [100]
  billing_cycle = "monthly"
  image_id = data.kamatera_image.ubuntu.id
  startup_script = var.defaults.rancher_server_startup_script
  password = var.defaults.rancher_server_password
  ssh_pubkey = var.defaults.ssh_pubkey
  network {
    name = "wan"
  }
  network {
    name = var.defaults.private_network_full_name
  }
}

locals {
  rancher_public_ip = kamatera_server.rancher.public_ips[0]
  rancher_domain = "${replace(local.rancher_public_ip, ".", "-")}.cloud-xip.io"
  rancher_url = "https://${local.rancher_domain}"
}
