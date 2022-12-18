resource "rancher2_cluster" "cluster" {
  name = var.name
  rke_config {
    kubernetes_version = "v1.23.14-rancher1-1"
    network {
      plugin = "none"
    }
    ingress {
      default_backend = true
      extra_args = {
        "default-ssl-certificate" = "ingress-nginx/${var.default_ssl_certificate_secret_name}",
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
  __nodes_startup_script = <<-EOF
    mkdir -p /etc/apt/keyrings &&\
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&\
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list &&\
    apt-get update &&\
    apt-get install -y "docker-ce=5:20.10.21~3-0~ubuntu-focal" "docker-ce-cli=5:20.10.21~3-0~ubuntu-focal" containerd.io &&\
    docker version &&\
    ${trimspace(rancher2_cluster.cluster.cluster_registration_token[0].node_command)}
  EOF
  nodes_startup_script = trimspace(local.__nodes_startup_script)
}
