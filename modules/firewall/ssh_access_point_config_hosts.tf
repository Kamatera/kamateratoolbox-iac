resource "null_resource" "set_ssh_access_point_private_key" {
  triggers = {
    command = <<-EOF
      if ! [ -f ~/.ssh/id_rsa ]; then
        echo "${file("${path.cwd}/${var.ssh_private_key_file}")}" > ~/.ssh/id_rsa &&\
        chmod 400 ~/.ssh/id_rsa
      fi
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

resource "null_resource" "set_ssh_access_point_config_hosts" {
  for_each = var.hosts
  triggers = {
    command = <<-EOF
      if ! grep -q "${each.value}" ~/.ssh/config; then
          echo "
      Host ${each.key}
        HostName ${each.value}
        User root
        IdentityFile ~/.ssh/id_rsa
      " >> ~/.ssh/config
      fi
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
