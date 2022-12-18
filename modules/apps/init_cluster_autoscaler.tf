module "cluster_autoscaler_argocd_sync" {
  source = "../common/admin_sync_argocd_app"
  domain = "${var.subdomain_prefix}-argocd-grpc.${var.root_domain}"
  app_name = "cluster-autoscaler"
  post_sync_script = <<-EOF
    sleep 10 &&\
    kubectl -n kube-system logs deployment/cluster-autoscaler
  EOF
}
