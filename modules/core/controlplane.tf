resource "kamatera_server" "controlplane" {
  name = "cloudcli-controlplane"
  datacenter_id = var.defaults.datacenter_id
  cpu_type = "B"
  cpu_cores = 4
  ram_mb = 4096
  disk_sizes_gb = [100]
  billing_cycle = "monthly"
  image_id = data.kamatera_image.ubuntu.id
  startup_script = <<-EOF
    ${local.nodes_startup_script} --etcd --controlplane
  EOF
  ssh_pubkey = var.defaults.ssh_pubkey
  network {
    name = "wan"
  }
  network {
    name = var.defaults.private_network_full_name
  }
}
