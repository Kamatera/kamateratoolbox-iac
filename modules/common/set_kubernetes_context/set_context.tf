resource "null_resource" "set_context" {
  triggers = {
    timestamp = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOF
      kubectl config set-context ${var.context_name}
    EOF
  }
}
