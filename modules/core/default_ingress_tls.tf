resource "null_resource" "default_ingress_tls" {
  depends_on = [module.set_context, null_resource.certbot]
  triggers = {
    command = <<-EOF
      python3 bin/default_ingress_tls.py "${kamatera_server.rancher.public_ips[0]}" "${var.defaults.root_domain}"
    EOF
    md5 = filemd5("${path.module}/bin/default_ingress_tls.py")
  }
  provisioner "local-exec" {
    command = <<-EOF
      cd ${path.module}
      ${self.triggers.command}
    EOF
  }
}
