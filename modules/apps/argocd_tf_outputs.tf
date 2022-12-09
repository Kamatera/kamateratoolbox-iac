resource "kubernetes_config_map" "tf_outputs" {
  depends_on = [
    null_resource.deploy_argocd
  ]
  metadata {
    name      = "tf-outputs"
    namespace = "argocd"
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "kubernetes_config_map_v1_data" "tf_outputs" {
  depends_on = [
    kubernetes_config_map.tf_outputs
  ]
  field_manager = "terraform_module_apps"
  metadata {
    name      = "tf-outputs"
    namespace = "argocd"
  }
  data = {
    root_domain = var.defaults.root_domain
    letsencrypt_email = var.defaults.letsencrypt_email
    cloudcli_server_domain = "cloudcli.${var.defaults.root_domain}"
    controlplane_public_ip = local.cloudcli.controlplane_ip
  }
}
