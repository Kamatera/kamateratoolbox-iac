output "apps" {
  value = {
    "argocd-admin-password" = "kubectl get secret -n argocd argocd-initial-admin-secret -ojsonpath={.data.password} | base64 -d"
  }
}
