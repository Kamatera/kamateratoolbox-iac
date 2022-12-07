module "set_context" {
  source = "../common/set_kubernetes_context"
  context_name = "cloudcli"
}

resource "null_resource" "deploy_argocd" {
  depends_on = [module.set_context]
  triggers = {
    command = "python3 apps/argocd/deploy.py ${var.defaults.root_domain} cloudcli"
    argocd_md5 = join(",", [for filename in fileset(path.cwd, "apps/argocd/**") : filemd5("${path.cwd}/${filename}")])
  }
  provisioner "local-exec" {
    command = <<-EOF
      cd ${path.cwd} &&\
      ${self.triggers.command}
    EOF
  }
}
