resource "null_resource" "httpauth" {
  for_each = toset([
    "prometheus",
    "alertmanager"
  ])
  triggers = {
    command = <<-EOF
      python3 bin/httpauth.py "${each.value}"
    EOF
    md5 = filemd5("${path.module}/bin/httpauth.py")
  }
  provisioner "local-exec" {
    command = <<-EOF
      cd ${path.module}
      ${self.triggers.command}
    EOF
  }
}
