variable "authorized_keys" {type = map(string)}
variable "ssh_access_point_public_ip" {}
variable "internal_ssh_host_name" {}
variable "private_key_file" {}

resource "null_resource" "set" {
  for_each = var.authorized_keys
  triggers = {
    command = <<-EOF
      if [ "${var.internal_ssh_host_name}" == "" ]; then
        SSH="bash -c"
      else
        SSH="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.internal_ssh_host_name}"
      fi
      $SSH '
        if ! grep -q "${each.value}" ~/.ssh/authorized_keys; then
          echo "
        # ${each.key}
        ${each.value}
        " >> ~/.ssh/authorized_keys
        fi
      '
    EOF
  }
  provisioner "remote-exec" {
    connection {
      host = var.ssh_access_point_public_ip
      private_key = file(var.private_key_file)
    }
    inline = ["#!/bin/bash", self.triggers.command]
  }
}
