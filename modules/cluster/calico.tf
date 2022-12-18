resource "null_resource" "deploy_calico" {
  depends_on = [null_resource.check_kuberenetes]
  triggers = {
    command = "python3 deploy_calico.py"
    md5 = md5(file("${path.module}/deploy_calico.py"))
  }
  provisioner "local-exec" {
    command = <<-EOF
      cd ${path.module} &&\
      ${local.set_context} &&\
      ${self.triggers.command}
    EOF
  }
}
