variable "hosts" {type = map(string)}
variable "ssh_private_key_file" {}
variable "ssh_additional_authorized_keys" {type = map(string)}
variable "datacenter_id" {}
variable "ssh_access_point_name" {}
variable "ssh_pubkey" {}
variable "private_network_full_name" {}
variable "cluster_context" {}
variable "argocd_grpc_domain" {}

terraform {
  required_providers {
    kamatera = {
      source = "Kamatera/kamatera"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = var.cluster_context
}

output "ssh_access_point_public_ip" {
  value = kamatera_server.ssh_access_point.public_ips[0]
}
