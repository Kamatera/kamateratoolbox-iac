module "set_context" {
  source = "../common/set_kubernetes_context"
  context_name = "cloudcli"
}

resource "null_resource" "check_kuberenetes" {
  depends_on = [module.set_context]
  provisioner "local-exec" {
    command = <<-EOF
      if [ "$(kubectl config current-context)" != "cloudcli" ]; then
        echo "Kubernetes context is not set to cloudcli"
        exit 1
      fi
      if ! kubectl get nodes; then
        echo "Kubernetes cluster is not reachable"
        exit 1
      fi
      echo "Kubernetes cluster is reachable"
    EOF
  }
}

resource "null_resource" "certbot" {
  depends_on = [module.set_context, null_resource.check_kuberenetes]
  triggers   = {
    command = <<-EOF
      python3 bin/certbot.py ${var.defaults.root_domain} ${var.defaults.letsencrypt_email}
    EOF
    md5 = filemd5("${path.module}/bin/certbot.py")
    certbot_md5 = join(",", [for filename in fileset(path.cwd, "docker/certbot/**") : filemd5("${path.cwd}/${filename}")])
  }
  provisioner "local-exec" {
    command = <<EOF
      cd ${path.module} &&\
      ${self.triggers.command}
    EOF
  }
  lifecycle {
    ignore_changes = all
  }
}
