resource "kubernetes_config_map" "tf_outputs" {
  metadata {
    name = "tf-outputs-cloudcli"
    namespace = "argocd"
  }
  data = {
    cloudcli_server_domain = "${var.sub_domain}.${var.root_domain}"
  }
}
