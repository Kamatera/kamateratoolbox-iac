variable "set_context" {}
variable "root_domain" {}
variable "subdomain_prefix" {}
variable "ingress_hostname" {}
variable "rancher_public_ip" {}
variable "ssh_private_key_file" {}
variable "default_ssl_certificate_secret_name" {}
variable "cluster_context" {}
variable "nfs_private_ip" {}
variable "initial_admin_user" {}
variable "name_suffix" {}
variable "datacenter_id" {}
variable "rancher_password" {}
variable "letsencrypt_email" {}
variable "ssh_pubkey_file" {}
variable "controlplane_public_ip" {}
variable "alert_email_addresses" {}

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = var.cluster_context
}

output "argocd" {
  value = {
    "url" = "https://${var.subdomain_prefix}-argocd.${var.root_domain}"
    "username" = "admin"
    "password" = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  }
}

output "vault" {
  value = {
    "url" = "https://${var.subdomain_prefix}-vault.${var.root_domain}"
    "root_token" = "kubectl -n kube-system get secret vault -o jsonpath='{.data.root_token}' | base64 -d"
  }
}

output "grafana" {
  value = {
    "url" = "https://${var.subdomain_prefix}-grafana.${var.root_domain}"
    "admin-password" = "vault kv get -mount=kv -field=admin-password iac/apps/grafana"
  }
}