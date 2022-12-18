resource "null_resource" "deploy_argocd" {
  triggers = {
    command = "python3 apps/argocd/deploy.py ${var.root_domain} ${var.subdomain_prefix}"
    md5 = join(",", [for filename in fileset(path.cwd, "apps/argocd/**") : filemd5("${path.cwd}/${filename}")])
  }
  provisioner "local-exec" {
    command = <<-EOF
      ${var.set_context} &&\
      cd ${path.cwd} &&\
      ${self.triggers.command}
    EOF
  }
}
