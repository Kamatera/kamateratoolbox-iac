resource "kamatera_server" "ssh_access_point" {
  name = "cloudcli-ssh-access-point"
  datacenter_id = var.defaults.datacenter_id
  cpu_type = "B"
  cpu_cores = 1
  ram_mb = 1024
  disk_sizes_gb = [10]
  billing_cycle = "monthly"
  image_id = data.kamatera_image.ubuntu.id
  ssh_pubkey = var.defaults.ssh_pubkey
  network {
    name = "wan"
  }
  network {
    name = var.defaults.private_network_full_name
  }
}

resource "null_resource" "ssh_access_point_key" {
  provisioner "remote-exec" {
    connection {
      host = kamatera_server.ssh_access_point.public_ips[0]
      private_key = file(var.defaults.ssh_private_key_file)
    }
    inline = [
      "#!/bin/bash",
      "mkdir -p ~/.ssh",
      "ssh-keygen -t rsa -b 4096 -C 'cloudcli ssh access point' -f ~/.ssh/id_rsa -N ''",
    ]
  }
}

module "get_ssh_access_point_key" {
  depends_on = [null_resource.ssh_access_point_key]
  source = "../common/external_data_command"
  script = <<-EOF
    PUBKEY="$(ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      root@${kamatera_server.ssh_access_point.public_ips[0]} "cat ~/.ssh/id_rsa.pub")"
    echo '{"pubkey": "'"$PUBKEY"'"}'
  EOF
}

resource "null_resource" "set_ssh_access_point_authorized_key" {
  for_each = merge(
    {
      ssh_access_point: module.get_ssh_access_point_key.output.pubkey
    },
    jsondecode(var.defaults.ssh_access_point_authorized_keys_json)
  )
  triggers = {
    value = each.value
  }
  provisioner "remote-exec" {
    connection {
      host = kamatera_server.ssh_access_point.public_ips[0]
      private_key = file(var.defaults.ssh_private_key_file)
    }
    inline = [
      "#!/bin/bash",
      <<-EOF
        if ! grep -q "${each.value}" ~/.ssh/authorized_keys; then
          echo "
        # ${each.key}
        ${each.value}
        " >> ~/.ssh/authorized_keys
        fi
      EOF
    ]
  }
}

resource "null_resource" "set_ssh_access_point_config_hosts" {
  depends_on = [null_resource.ssh_access_point_key]
  for_each = merge(
    {
      "cloudcli-rancher": kamatera_server.rancher.private_ips[0]
      "cloudcli-controlplane": kamatera_server.controlplane.private_ips[0]
      "cloudcli-nfs": kamatera_server.nfs.private_ips[0]
    },
    {
      for each in kamatera_server.workers : each.name => each.private_ips[0]
    }
  )
  triggers = {
    v = "2"
    ssh_config = <<-EOF
      Host ${each.key}
        HostName ${each.value}
        User root
        IdentityFile ~/.ssh/id_rsa
    EOF
  }
  provisioner "remote-exec" {
    connection {
      host = kamatera_server.ssh_access_point.public_ips[0]
      private_key = file(var.defaults.ssh_private_key_file)
    }
    inline = [
      "#!/bin/bash",
      <<-EOF
        if ! grep -q "${each.value}" ~/.ssh/config; then
          echo "
      ${self.triggers.ssh_config}
      " >> ~/.ssh/config
        fi
      EOF
    ]
  }
}

resource "null_resource" "set_rancher_authorized_key" {
  for_each = merge(
    {
      ssh_access_point: module.get_ssh_access_point_key.output.pubkey
    },
    jsondecode(var.defaults.ssh_access_point_authorized_keys_json)
  )
  triggers = {
    value = each.value
  }
  provisioner "remote-exec" {
    connection {
      host = kamatera_server.rancher.public_ips[0]
      private_key = file(var.defaults.ssh_private_key_file)
    }
    inline = [
      "#!/bin/bash",
      <<-EOF
        if ! grep -q "${each.value}" ~/.ssh/authorized_keys; then
          echo "
        # ${each.key}
        ${each.value}
        " >> ~/.ssh/authorized_keys
        fi
      EOF
    ]
  }
}

resource "null_resource" "set_nfs_authorized_key" {
  for_each = merge(
    {
      ssh_access_point: module.get_ssh_access_point_key.output.pubkey
    },
    jsondecode(var.defaults.ssh_access_point_authorized_keys_json)
  )
  triggers = {
    value = each.value
  }
  provisioner "remote-exec" {
    connection {
      host = kamatera_server.nfs.public_ips[0]
      private_key = file(var.defaults.ssh_private_key_file)
    }
    inline = [
      "#!/bin/bash",
      <<-EOF
        if ! grep -q "${each.value}" ~/.ssh/authorized_keys; then
          echo "
        # ${each.key}
        ${each.value}
        " >> ~/.ssh/authorized_keys
        fi
      EOF
    ]
  }
}

resource "kubernetes_namespace" "cluster_admin" {
  metadata {
    name = "cluster-admin"
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "kubernetes_config_map" "ssh_authorized_keys" {
  metadata {
    name = "ssh-authorized-keys"
    namespace = "cluster-admin"
  }
  data = merge(
    {
      SSHKEY_ssh_access_point: module.get_ssh_access_point_key.output.pubkey
    },
    {
      for k, v in jsondecode(var.defaults.ssh_access_point_authorized_keys_json): "SSHKEY_${k}" => v
    }
  )
}
