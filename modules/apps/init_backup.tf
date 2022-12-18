module "backup_argocd_sync" {
  source = "../common/admin_sync_argocd_app"
  domain = "${var.subdomain_prefix}-argocd-grpc.${var.root_domain}"
  app_name = "backup"
}
