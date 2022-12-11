resource "kubernetes_config_map" "tf_outputs" {
  depends_on = [module.set_context]
  metadata {
    name      = "tf-outputs"
    namespace = "argocd"
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "kubernetes_config_map_v1_data" "tf_outputs" {
  depends_on = [kubernetes_config_map.tf_outputs]
  field_manager = "terraform_module_core"
  metadata {
    name      = "tf-outputs"
    namespace = "argocd"
  }
  data = {
    root_domain = var.defaults.root_domain
    letsencrypt_email = var.defaults.letsencrypt_email
    nfs_private_ip = kamatera_server.nfs.private_ips[0]
    controlplane_public_ip = kamatera_server.controlplane.public_ips[0]
  }
}
