resource "kubernetes_config_map_v1_data" "ingress_tcp_ports" {
  depends_on = [
    kubernetes_config_map.tf_outputs
  ]
  field_manager = "terraform_module_apps"
  metadata {
    name      = "tcp-services"
    namespace = "ingress-nginx"
  }
  data = {
    "9941": "terraform/state-db:5432"
  }
}

resource "null_resource" "patch_ingress_tcp_ports" {
  depends_on = [module.set_context]
  provisioner "local-exec" {
    command = <<-EOF
      kubectl -n ingress-nginx patch daemonset nginx-ingress-controller \
        --type='json' \
        -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports/-", "value": {"name": "tfstatedb", "containerPort": 9941, "hostPort": 9941, "protocol": "TCP"}}]'
    EOF
  }
}
