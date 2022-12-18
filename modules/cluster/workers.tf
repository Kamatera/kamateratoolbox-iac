locals {
  worker_names = {
    "1": "${var.name}-worker1_1",
    "2": "${var.name}-worker2",
    "3": "${var.name}-worker3",
  }
}

resource "kamatera_server" "workers" {
  for_each = local.worker_names
  name = each.value
  datacenter_id = var.datacenter_id
  cpu_type = "B"
  cpu_cores = 4
  ram_mb = 8192
  disk_sizes_gb = [100]
  billing_cycle = "monthly"
  image_id = data.kamatera_image.ubuntu.id
  startup_script = <<-EOF
    ${local.nodes_startup_script} --worker
  EOF
  ssh_pubkey = var.ssh_pubkey
  network {
    name = var.private_network_full_name
  }
  network {
    name = "wan"
  }
  lifecycle {
    ignore_changes = [network, startup_script, ssh_pubkey, image_id]
  }
}
