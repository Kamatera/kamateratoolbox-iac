resource "kamatera_server" "workers" {
  count = 3
  name = "cloudcli-worker-${count.index}"
  datacenter_id = var.defaults.datacenter_id
  cpu_type = "B"
  cpu_cores = 4
  ram_mb = 8192
  disk_sizes_gb = [100]
  billing_cycle = "monthly"
  image_id = data.kamatera_image.ubuntu.id
  startup_script = <<-EOF
    ${local.nodes_startup_script} --worker
  EOF
  ssh_pubkey = var.defaults.ssh_pubkey
  network {
    name = "wan"
  }
  network {
    name = var.defaults.private_network_full_name
  }
}
