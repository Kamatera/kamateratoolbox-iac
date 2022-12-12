variable "name" {}

resource "null_resource" "httpauth" {
  triggers = {
    command = <<-EOF
      python3 set_httpauth_secret.py "${var.name}"
    EOF
    md5 = filemd5("${path.module}/set_httpauth_secret.py")
  }
  provisioner "local-exec" {
    command = <<-EOF
      cd ${path.module}
      kubectl config set-context cloudcli &&\
      ${self.triggers.command}
    EOF
  }
}
