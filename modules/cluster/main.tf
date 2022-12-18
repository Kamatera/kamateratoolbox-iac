variable "name" {}
variable "rancher_url" {}
variable "datacenter_id" {}
variable "ssh_pubkey" {}
variable "private_network_full_name" {}
variable "root_domain" {}
variable "default_ingress_subdomain" {}
variable "default_ssl_certificate_secret_name" {}
variable "autoscaler_cluster_name" {}
variable "autoscaler_nodegroup_name" {}
variable "autoscaler_nodegroup_name_prefix" {}

terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
    }
    kamatera = {
      source = "Kamatera/kamatera"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

provider "rancher2" {
  api_url = var.rancher_url
}

output "cluster_context" {
  value = rancher2_cluster.cluster.name
}

output "set_context" {
  value = local.set_context
}

output "ingress_hostname" {
  value = values(cloudflare_record.ingress)[0].hostname
}

output "controlplane_public_ip" {
  value = kamatera_server.controlplane.public_ips[0]
}

output "kubeconfig" {
  value = rancher2_cluster.cluster.kube_config
  sensitive = true
}
