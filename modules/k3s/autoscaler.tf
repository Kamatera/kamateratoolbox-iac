locals {
  autoscaler_nodes_startup_script = <<-EOF
    PUBLIC_IP=$(echo $(ip -4 addr show dev eth1 | grep inet) | cut -d' ' -f2 | cut -d'/' -f1) &&\
    PRIVATE_IP=$(echo $(ip -4 addr show dev eth0 | grep inet) | cut -d' ' -f2 | cut -d'/' -f1) &&\
    curl -sfL https://get.k3s.io | K3S_URL=https://${local.controlplane_private_ip}:6443 K3S_TOKEN=${local.k3s_token} sh -s - \
      --node-name "$${HOSTNAME}" \
      --node-ip "$${PRIVATE_IP}" \
      --node-external-ip "$${PUBLIC_IP}"
  EOF
}

resource "null_resource" "autoscaler_config_secret" {
  # depends_on = [null_resource.kubeconfig]
  triggers = {
    v = "3"
    command = <<-EOF
      python3 create_autoscaler_config_secret.py \
        "${var.datacenter_id}" \
        "${kamatera_server.k3s["worker1"].image_id}" \
        "${var.private_network_full_name}" \
        4B 8192 200 \
        "${base64encode(local.autoscaler_nodes_startup_script)}" \
        "${var.ssh_pubkey}" \
        "${var.autoscaler_cluster_name}" \
        "${var.autoscaler_nodegroup_name}" \
        "${var.autoscaler_nodegroup_name_prefix}"
    EOF
  }
  provisioner "local-exec" {
    command = <<EOF
      export KUBECONFIG=/etc/kamatera/cloudcli/kubeconfig &&\
      cd ${path.module} &&\
      ${self.triggers.command}
    EOF
  }
}
