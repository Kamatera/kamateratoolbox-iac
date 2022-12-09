output "apps" {
  value = {
    "argocd" = {
      "url" = "https://cloudcli-argocd.${var.defaults.root_domain}"
      "username" = "admin"
      "password" = "kubectl get secret -n argocd argocd-initial-admin-secret -ojsonpath={.data.password} | base64 -d"
    }
  }
}
