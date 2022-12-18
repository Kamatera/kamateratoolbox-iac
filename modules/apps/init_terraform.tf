resource "null_resource" "terraform_init" {
  triggers = {
    command = <<-EOF
      TEMPDIR=$(mktemp -d) &&\
      cd $TEMPDIR &&\
      BACKEND_DB_PASSWORD=$(pwgen -s 32 1) &&\
      openssl req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key -subj "/CN=terraform-state-db.localhost" &&\
      export VAULT_TOKEN="$(kubectl -n kube-system get secret vault -o jsonpath='{.data.root_token}' | base64 -d)" &&\
      export VAULT_ADDR="https://${var.subdomain_prefix}-vault.${var.root_domain}" &&\
      vault kv put -mount=kv iac/terraform/state_db \
        backend-db-password=$BACKEND_DB_PASSWORD \
        state_db_server.key="$(cat server.key)" \
        state_db_server.crt="$(cat server.crt)"
      RET=$?
      rm -rf $TEMPDIR
      exit $RET
    EOF
  }
  provisioner "local-exec" {
    command = self.triggers.command
  }
  lifecycle {
    ignore_changes = all
  }
}

module "terraform_argocd_sync" {
  source = "../common/admin_sync_argocd_app"
  domain = "${var.subdomain_prefix}-argocd-grpc.${var.root_domain}"
  app_name = "terraform"
  post_sync_script = <<-EOF
    sleep 2 &&\
    kubectl -n terraform rollout restart deployment/state-db &&\
    sleep 5
  EOF
}

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
  field_manager = "terraform_module_apps"
  metadata {
    name = "tcp-services"
    namespace = "ingress-nginx"
  }
  data = local.add_ingress_tcp_port_configmap
}

resource "null_resource" "terraform_state_db_add_ingress_tcp_port_daemonset" {
  provisioner "local-exec" {
    command = <<-EOF
      ${var.set_context} &&\
      kubectl -n ingress-nginx patch daemonset nginx-ingress-controller \
        --type='json' \
        -p='${local.patch_ingress_tcp_port_daemonset_json}'
    EOF
  }
}
