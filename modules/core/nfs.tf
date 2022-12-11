data "kamatera_image" "nfsserver" {
  datacenter_id = var.defaults.datacenter_id
  private_image_name = "service_nfs_nfsserver-ubuntuserver-20.04"
}

resource "kamatera_server" "nfs" {
  name = "cloudcli-nfs_1"
  datacenter_id = var.defaults.datacenter_id
  cpu_type = "B"
  cpu_cores = 1
  ram_mb = 2048
  disk_sizes_gb = [50]
  billing_cycle = "monthly"
  image_id = data.kamatera_image.nfsserver.id
  ssh_pubkey = var.defaults.ssh_pubkey
  daily_backup = true
  network {
    name = "wan"
  }
  network {
    name = var.defaults.private_network_full_name
  }
}

resource "null_resource" "nfs_no_root_squash" {
  depends_on = [kamatera_server.nfs]
  provisioner "remote-exec" {
    connection {
      host = kamatera_server.nfs.public_ips[0]
      user = "root"
      password = kamatera_server.nfs.generated_password
    }
    inline = [
      "sed -i 's/no_subtree_check)/no_subtree_check,no_root_squash)/' /etc/exports",
      "systemctl restart nfs-kernel-server"
    ]
  }
}

#resource "null_resource" "test_ssh_access" {
#  provisioner "remote-exec" {
#    connection {
#      host = kamatera_server.nfs.public_ips[0]
#      private_key = file(var.defaults.ssh_private_key_file)
#    }
#    inline = [
#      "#!/bin/bash",
#      "echo 'ssh access works'",
#      "ls -lah",
#      "if [[ -f /etc/exports ]]; then echo 'file exists'; else echo 'file does not exist'; fi"
#    ]
#  }
#}
