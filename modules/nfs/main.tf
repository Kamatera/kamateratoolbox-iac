terraform {
  required_providers {
    kamatera = {
      source = "Kamatera/kamatera"
    }
  }
}

variable "datacenter_id" {}
variable "name" {}
variable "ssh_pubkey" {}
variable "private_network_full_name" {}
variable "ssh_private_key_file" {}

data "kamatera_image" "nfsserver" {
  datacenter_id = var.datacenter_id
  private_image_name = "service_nfs_nfsserver-ubuntuserver-20.04"
}

resource "kamatera_server" "nfs" {
  name = var.name
  datacenter_id = var.datacenter_id
  cpu_type = "B"
  cpu_cores = 1
  ram_mb = 2048
  disk_sizes_gb = [50]
  billing_cycle = "monthly"
  image_id = data.kamatera_image.nfsserver.id
  ssh_pubkey = var.ssh_pubkey
  daily_backup = true
  network {
    name = "wan"
  }
  network {
    name = var.private_network_full_name
  }
}

resource "null_resource" "nfs_no_root_squash" {
  depends_on = [kamatera_server.nfs]
  provisioner "remote-exec" {
    connection {
      host = kamatera_server.nfs.public_ips[0]
      private_key = file(var.ssh_private_key_file)
    }
    inline = [
      "sed -i 's/no_subtree_check)/no_subtree_check,no_root_squash)/' /etc/exports",
      "systemctl restart nfs-kernel-server"
    ]
  }
}

output "private_ip" {
  value = kamatera_server.nfs.private_ips[0]
}
