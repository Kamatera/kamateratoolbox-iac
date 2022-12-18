resource "null_resource" "nfs_firewall" {
  triggers = {
    command = <<-EOF
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null nfs '
        INTERNAL_IFACE="$(ip -4 -o addr | grep " inet 172.16." | cut -f2 -d" ")"
        if [ "$INTERNAL_IFACE" != "eth0" ] && [ "$INTERNAL_IFACE" != "eth1" ]; then
          echo "ERROR: INTERNAL_IFACE is not eth0 or eth1"
          exit 1
        fi &&\
        echo "INTERNAL_IFACE=$INTERNAL_IFACE" &&\
        ufw --force reset &&\
        ufw default allow outgoing &&\
        ufw default deny incoming &&\
        ufw default deny routed &&\
        ufw allow in on $INTERNAL_IFACE &&\
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
