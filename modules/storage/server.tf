data "kamatera_image" "nfsserver" {
  datacenter_id = var.defaults.datacenter_id
  private_image_name = "service_nfs_nfsserver-ubuntuserver-20.04"
}

resource "kamatera_server" "nfs" {
  name = "cloudcli-nfs"
  datacenter_id = var.defaults.datacenter_id
  cpu_type = "B"
  cpu_cores = 1
  ram_mb = 2048
  disk_sizes_gb = [50]
  billing_cycle = "monthly"
  image_id = data.kamatera_image.nfsserver.id
  ssh_pubkey = var.defaults.ssh_pubkey
  network {
    name = "wan"
  }
  network {
    name = var.defaults.private_network_full_name
  }
}
