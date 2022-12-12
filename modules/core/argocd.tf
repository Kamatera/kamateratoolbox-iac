resource "null_resource" "deploy_argocd" {
  depends_on = [null_resource.check_kuberenetes]
  triggers = {
    command = "python3 apps/argocd/deploy.py ${var.defaults.root_domain} cloudcli"
    argocd_md5 = join(",", [for filename in fileset(path.cwd, "apps/argocd/**") : filemd5("${path.cwd}/${filename}")])
  }
  provisioner "local-exec" {
    command = <<-EOF
      cd ${path.cwd} &&\
      kubectl config set-context cloudcli &&\
      ${self.triggers.command}
    EOF
  }
}
