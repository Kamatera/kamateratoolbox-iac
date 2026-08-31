data "kamatera_image" "ubuntu_2404" {
  datacenter_id = var.datacenter_id
  os = "Ubuntu"
  code = "24.04 64bit"
}

resource "kamatera_server" "bastion" {
  name = "${local.name_prefix}-bastion"
  datacenter_id = var.datacenter_id
  cpu_type = "B"
  cpu_cores = 2
  ram_mb = 2048
  disk_sizes_gb = [50]
  billing_cycle = "monthly"
  monthly_traffic_package = "t5000"
  image_id = data.kamatera_image.ubuntu_2404.id
  ssh_pubkey = file("${path.cwd}/${var.ssh_pubkey_file}")
  network {
    name = module.private_network.full_name
  }
  network {
    name = "wan"
  }
}
