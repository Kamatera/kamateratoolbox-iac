resource "null_resource" "rke2_node_settings" {
  for_each = {for name, server in var.servers : name => server}
  triggers = {
    command = <<-EOF
      #!/bin/bash
      set -euo pipefail
      cat > /etc/sysctl.d/99-cwm.conf <<EOL
        vm.max_map_count = 262144
        net.ipv4.tcp_retries2 = 8
        fs.inotify.max_user_instances = 1024
        fs.inotify.max_user_watches   = 2097152
        fs.inotify.max_queued_events  = 65536
        net.core.somaxconn = 65535
        net.core.netdev_max_backlog = 250000
        net.ipv4.tcp_max_syn_backlog = 8192
        net.core.default_qdisc = fq
        net.core.rps_sock_flow_entries = 65536
      EOL
      sysctl --system
      rm -f /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf
      cat > /etc/systemd/system/rps.service <<'EOL'
        [Unit]
        Description=Enable RPS
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=oneshot
        ExecStart=/bin/sh -c ' \
        for q in /sys/class/net/eth*/queues/rx-*; do \
          echo ff > $q/rps_cpus; \
          echo 32768 > $q/rps_flow_cnt; \
        done'

        [Install]
        WantedBy=multi-user.target
      EOL
      systemctl daemon-reload
      systemctl restart systemd-networkd-wait-online.service || true
      systemctl enable rps.service
      systemctl start rps.service
      if ! [ -e /root/.ssh/id_rsa ]; then ssh-keygen -t rsa -b 4096 -N '' -f /root/.ssh/id_rsa; fi
      echo 'export PATH="/var/lib/rancher/rke2/bin/:$PATH"' > /etc/profile.d/00-cwm.sh
      echo 'export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml' >> /etc/profile.d/00-cwm.sh
      echo 'export CONTAINERD_ADDRESS=/run/k3s/containerd/containerd.sock' >> /etc/profile.d/00-cwm.sh
      echo 'export CONTAINERD_NAMESPACE=k8s.io' >> /etc/profile.d/00-cwm.sh
      echo 'export KUBECONFIG="/etc/rancher/rke2/rke2.yaml"' >> /etc/profile.d/00-cwm.sh
      if ! ip addr show eth1 | grep '172\.16\.'; then
          echo "Error: eth1 must have the internal IP"
          exit 1
      fi
    EOF
  }
  provisioner "remote-exec" {
    connection {
      host = local.server_public_ip[each.key]
      private_key = file(var.ssh_private_key_file)
    }
    inline = [self.triggers.command]
  }
}

locals {
  controlplane1_servers = [for name, server in var.servers : name if server.role == "controlplane1"]
  controlplane1_server_name = length(local.controlplane1_servers) > 0 ? local.controlplane1_servers[0] : ""
  controlplane1_private_ip = length(local.controlplane1_servers) > 0 ? local.server_private_ip[local.controlplane1_server_name] : ""
  controlplane1_public_ip = length(local.controlplane1_servers) > 0 ? local.server_public_ip[local.controlplane1_server_name] : ""
}

output "controlplane1_node_name" {
  value = local.controlplane1_server_name
}

resource "null_resource" "rke2_install_controlplane1" {
  triggers = {
    command = <<-EOT
    #!/bin/bash
    set -euo pipefail
    mkdir -p /etc/rancher/rke2
    cat > /etc/rancher/rke2/config.yaml <<'EOL'
    node-name: controlplane1
    node-ip: ${local.controlplane1_private_ip}
    node-external-ip: ${local.controlplane1_public_ip}
    advertise-address: ${local.controlplane1_private_ip}
    tls-san:
      - 0.0.0.0
      - ${local.controlplane1_private_ip}
      - ${local.controlplane1_public_ip}
    etcd-snapshot-retention: 14  # snapshot every 12 hours, total of 1 week
    EOL
    curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${var.rke2_version} sh - &&\
    if systemctl is-active --quiet rke2-server.service; then
      systemctl restart rke2-server.service
    else
      systemctl enable rke2-server.service &&\
      systemctl start rke2-server.service
    fi
  EOT
  }
  provisioner "remote-exec" {
    connection {
      host = local.server_public_ip[local.controlplane1_server_name]
      private_key = file(var.ssh_private_key_file)
    }
    inline = [self.triggers.command]
  }
}

resource "null_resource" "rke2_install_secondary_controlplanes" {
  for_each = {for name, server in var.servers : name => server if server.role == "controlplane"}
  triggers = {
    command = <<-EOF
      #!/bin/bash
      set -euo pipefail
      mkdir -p /etc/rancher/rke2
      echo "${trimspace(file(var.node_token_path))}" > /etc/rancher/rke2/node-token
      cat > /etc/rancher/rke2/config.yaml <<'EOL'
      token-file: /etc/rancher/rke2/node-token
      server: https://${local.controlplane1_private_ip}:9345
      node-name: ${each.key}
      node-ip: ${local.server_private_ip[each.key]}
      node-external-ip: ${local.server_public_ip[each.key]}
      advertise-address: ${local.server_private_ip[each.key]}
      tls-san:
        - 0.0.0.0
        - ${local.server_private_ip[each.key]}
        - ${local.server_public_ip[each.key]}
      etcd-snapshot-retention: 14  # snapshot every 12 hours, total of 1 week
      EOL
      curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${var.rke2_version} INSTALL_RKE2_TYPE=server sh - &&\
      if systemctl is-active --quiet rke2-server.service; then
        systemctl restart rke2-server.service
      else
        systemctl enable rke2-server.service &&\
        systemctl start rke2-server.service
      fi
    EOF
  }
  provisioner "remote-exec" {
    connection {
      host = local.server_public_ip[each.key]
      private_key = file(var.ssh_private_key_file)
    }
    inline = [self.triggers.command]
  }
}

resource "null_resource" "rke2_install_workers" {
  for_each = {for name, server in var.servers : name => server if server.role == "worker"}
  triggers = {
    command = <<-EOF
      #!/bin/bash
      set -euo pipefail
      mkdir -p /etc/rancher/rke2
      echo "${trimspace(file(var.node_token_path))}" > /etc/rancher/rke2/node-token
      cat > /etc/rancher/rke2/config.yaml <<'EOL'
      node-name: ${each.key}
      node-ip: ${local.server_private_ip[each.key]}
      node-external-ip: ${local.server_public_ip[each.key]}
      token-file: /etc/rancher/rke2/node-token
      server: https://${local.controlplane1_private_ip}:9345
      EOL
      curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${var.rke2_version} INSTALL_RKE2_TYPE=agent sh - &&\
      if systemctl is-active --quiet rke2-agent.service; then
        systemctl restart rke2-agent.service
      else
        systemctl enable rke2-agent.service &&\
        systemctl start rke2-agent.service
      fi
    EOF
  }
  provisioner "remote-exec" {
    connection {
      host = local.server_public_ip[each.key]
      private_key = file(var.ssh_private_key_file)
    }
    inline = [self.triggers.command]
  }
}

data "external" "admin_kubeconfig" {
  program = [
    "bash", "-c", <<-EOT
      set -euo pipefail
      FILENAME=${var.admin_kubeconfig_path}
      if ! [ -f "$FILENAME" ]; then
        ssh -i "${var.ssh_private_key_file}" \
          -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          root@${local.controlplane1_public_ip} "cat /etc/rancher/rke2/rke2.yaml" > "$FILENAME"
        sed -i 's|https://127.0.0.1:6443|https://${local.controlplane1_public_ip}:6443|' "$FILENAME"
      fi
      echo '{}'
    EOT
  ]
}
