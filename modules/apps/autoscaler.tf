resource "null_resource" "autoscaler_config_secret" {
  depends_on = [module.set_context]
  triggers = {
    command = <<-EOF
      python3 bin/create_autoscaler_config_secret.py \
        "${var.defaults.datacenter_id}" \
        "${var.defaults.workers_image_id}" \
        "${var.defaults.private_network_full_name}" \
        2B 4096 100 \
        "${base64encode(local.cloudcli.nodes_startup_script)}" \
        "${var.defaults.ssh_pubkey}"
    EOF
  }
  provisioner "local-exec" {
    command = <<EOF
      cd ${path.module}
      ${self.triggers.command}
    EOF
  }
}
