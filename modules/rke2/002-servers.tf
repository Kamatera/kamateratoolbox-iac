data "kamatera_image" "ubuntu_2404" {
  datacenter_id = var.datacenter_id
  os = "Ubuntu"
  code = "24.04 64bit"
}

resource "kamatera_server" "servers" {
  for_each = var.servers
  datacenter_id = var.datacenter_id
  image_id = data.kamatera_image.ubuntu_2404.id
  name = "${var.name_prefix}-rke2-${each.key}"
  allow_recreate = true
  billing_cycle = "monthly"
  monthly_traffic_package = "t5000"

  cpu_cores = 4
  cpu_type = "B"
  disk_sizes_gb = [200]
  ram_mb = 8192
  ssh_pubkey = var.ssh_pubkey
  network {
    name = "wan"
  }
  network {
    name = var.use_existing_private_network_full_name
  }
}

locals {
  server_public_ip = {
    for name, _ in var.servers : name => kamatera_server.servers[name].public_ips[0]
  }
  server_private_ip = {
    for name, _ in var.servers : name => kamatera_server.servers[name].private_ips[0]
  }
}

output "server_private_ips" {
  value = local.server_private_ip
}

output "server_public_ips" {
  value = local.server_public_ip
}
