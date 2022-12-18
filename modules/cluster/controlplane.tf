data "kamatera_image" "ubuntu" {
  datacenter_id = var.datacenter_id
  os = "Ubuntu"
  code = "20.04 64bit_optimized_updated"
}

resource "kamatera_server" "controlplane" {
  name = "${var.name}-controlplane_1"
  datacenter_id = var.datacenter_id
  cpu_type = "B"
  cpu_cores = 4
  ram_mb = 4096
  disk_sizes_gb = [100]
  billing_cycle = "monthly"
  image_id = data.kamatera_image.ubuntu.id
  startup_script = <<-EOF
    ${local.nodes_startup_script} --etcd --controlplane
  EOF
  ssh_pubkey = var.ssh_pubkey
  network {
    name = var.private_network_full_name
  }
  network {
    name = "wan"
  }
}