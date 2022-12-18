resource "kubernetes_config_map" "tf_outputs" {
  metadata {
    name = "tf-outputs"
    namespace = "argocd"
  }
  data = {
    root_domain = var.root_domain
    subdomain_prefix = var.subdomain_prefix
    letsencrypt_email = var.letsencrypt_email
    nfs_private_ip = var.nfs_private_ip
    controlplane_public_ip = var.controlplane_public_ip
  }
}
