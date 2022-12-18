resource "null_resource" "rancher_firewall" {
  triggers = {
    command = <<-EOF
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null rancher '
        INTERNAL_IFACE="$(ip -4 -o addr | grep " inet 172.16." | cut -f2 -d" ")"
        if [ "$INTERNAL_IFACE" == "eth0" ]; then
          EXTERNAL_IFACE="eth1"
        elif [ "$INTERNAL_IFACE" == "eth1" ]; then
          EXTERNAL_IFACE="eth0"
        else
          echo "ERROR: Could not determine external interface"
          exit 1
        fi &&\
        echo "EXTERNAL_IFACE=$EXTERNAL_IFACE" &&\
        ufw --force reset &&\
        ufw default allow outgoing &&\
        ufw default allow incoming &&\
        ufw default deny routed &&\
        ufw deny in on $EXTERNAL_IFACE to any port 22 &&\
        ufw --force enable &&\
        ufw status verbose
      '
    EOF
  }
  provisioner "remote-exec" {
    connection {
      host = kamatera_server.ssh_access_point.public_ips[0]
      private_key = file("${path.cwd}/${var.ssh_private_key_file}")
    }
    inline = ["#!/bin/bash", self.triggers.command]
  }
}
