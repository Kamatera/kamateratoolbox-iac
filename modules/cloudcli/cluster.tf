resource "rancher2_cluster" "cloudcli" {
  name = "cloudcli"
  rke_config {
    kubernetes_version = "v1.23.14-rancher1-1"
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
