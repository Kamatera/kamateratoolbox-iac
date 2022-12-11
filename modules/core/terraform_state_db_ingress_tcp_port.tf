locals {
  add_ingress_tcp_port_configmap = {
    "9941": "terraform/state-db:5432"
  }
  patch_ingress_tcp_port_daemonset_json = jsonencode([
    {
      op: "add"
      path: "/spec/template/spec/containers/0/ports/-"
      value: {
        name: "tfstatedb"
        containerPort: 9941
        hostPort: 9941
        protocol: "TCP"
      }
    }
  ])
}

resource "kubernetes_config_map_v1_data" "terraform_state_db_add_ingress_tcp_port_configmap" {
  depends_on = [module.set_context]
  field_manager = "terraform_module_core"
  metadata {
    name = "tcp-services"
    namespace = "ingress-nginx"
  }
  data = local.add_ingress_tcp_port_configmap
}

resource "null_resource" "terraform_state_db_add_ingress_tcp_port_daemonset" {
  depends_on = [module.set_context]
  provisioner "local-exec" {
    command = <<-EOF
      kubectl -n ingress-nginx patch daemonset nginx-ingress-controller \
        --type='json' \
        -p='${local.patch_ingress_tcp_port_daemonset_json}'
    EOF
  }
}
