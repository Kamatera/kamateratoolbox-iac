resource "rancher2_cluster" "cloudcli" {
  name = "cloudcli"
  rke_config {
    kubernetes_version = "v1.24.8-rancher1-1"
    enable_cri_dockerd = true
    network {
      plugin = "canal"
    }
    ingress {
      default_backend = true
      extra_args = {
        "default-ssl-certificate" = "ingress-nginx/cloudcli-default-ssl",
      }
    }
  }
}
