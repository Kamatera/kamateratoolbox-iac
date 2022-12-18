output "cluster_context" {
  value = module.cluster.cluster_context
}

output "kubeconfig" {
  value = module.cluster.kubeconfig
  sensitive = true
}

output "apps" {
  value = {
    argocd = module.apps.argocd
    vault = module.apps.vault
    grafana = module.apps.grafana
  }
}

output "ingress_hostname" {
  value = module.cluster.ingress_hostname
}

output "ssh_access_point_public_ip" {
  value = module.firewall.ssh_access_point_public_ip
}
