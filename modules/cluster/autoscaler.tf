locals {
  autoscaler_nodes_startup_script = <<-EOF
    ${trimspace(local.nodes_startup_script)} --worker
  EOF
}

resource "null_resource" "autoscaler_config_secret" {
  depends_on = [null_resource.check_kuberenetes]
  triggers = {
    command = <<-EOF
      python3 create_autoscaler_config_secret.py \
        "${var.datacenter_id}" \
        "${data.kamatera_image.ubuntu.id}" \
        "${var.private_network_full_name}" \
        2B 4096 100 \
        "${base64encode(local.autoscaler_nodes_startup_script)}" \
        "${var.ssh_pubkey}" \
        "${var.autoscaler_cluster_name}" \
        "${var.autoscaler_nodegroup_name}" \
        "${var.autoscaler_nodegroup_name_prefix}"
    EOF
  }
  provisioner "local-exec" {
    command = <<EOF
      ${local.set_context} &&\
      cd ${path.module} &&\
      ${self.triggers.command}
    EOF
  }
}
