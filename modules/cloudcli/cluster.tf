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
    services {
      kubeproxy {
        extra_args = {
          "metrics-bind-address" = "0.0.0.0:10249",
        }
      }
    }
  }
}

locals {
  nodes_startup_script = "${trimspace(var.defaults.nodes_startup_script)} &&\\\n ${trimspace(rancher2_cluster.cloudcli.cluster_registration_token[0].node_command)}"
}
