# data "kamatera_image" "ubuntu" {
#   datacenter_id = var.datacenter_id
#   os = "Ubuntu"
#   code = "20.04 64bit_optimized_updated"
# }

resource "kamatera_server" "ssh_access_point" {
  name = var.ssh_access_point_name
  datacenter_id = var.datacenter_id
  cpu_type = "B"
  cpu_cores = 1
  ram_mb = 1024
  disk_sizes_gb = [10]
  billing_cycle = "monthly"
  image_id = "EU:6000C29f313b496da71f669782d04b75"  # data.kamatera_image.ubuntu.id
  ssh_pubkey = var.ssh_pubkey
  network {
    name = var.private_network_full_name
  }
  network {
    name = "wan"
  }
}

