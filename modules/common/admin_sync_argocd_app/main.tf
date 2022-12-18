variable "domain" {}
variable "app_name" {}
variable "post_sync_script" {default = "true"}
variable "extra_sync_args" {default = ""}

resource "null_resource" "sync" {
  triggers = {
    command = <<-EOF
      ARGOCD_ADMIN_PASSWORD="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)" &&\
      argocd login ${var.domain} --name cloudcli-prod-admin \
        --username admin --password $ARGOCD_ADMIN_PASSWORD &&\
      argocd app get ${var.app_name} --hard-refresh &&\
      argocd app sync --force ${var.extra_sync_args} ${var.app_name} &&\
      ${trimspace(var.post_sync_script)}
    EOF
  }
  provisioner "local-exec" {
    command = self.triggers.command
  }
}
