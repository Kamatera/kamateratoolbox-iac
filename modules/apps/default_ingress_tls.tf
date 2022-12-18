resource "null_resource" "default_ingress_tls" {
  triggers = {
    command = <<-EOF
      python3 default_ingress_tls.py \
        "${var.rancher_public_ip}" \
        "${var.root_domain}" \
        "../../${var.ssh_private_key_file}" \
        "${var.default_ssl_certificate_secret_name}"
    EOF
    md5 = filemd5("${path.module}/default_ingress_tls.py")
  }
  provisioner "local-exec" {
    command = <<-EOF
      ${var.set_context} &&\
      cd ${path.module} &&\
      ${self.triggers.command}
    EOF
  }
}
