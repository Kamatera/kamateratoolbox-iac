resource "null_resource" "prepare_rancher_server_for_build" {
  triggers = {
    command = <<-EOF
      bin/ssh.sh rancher "apt-get update && apt-get install -y zip"
    EOF
  }
  provisioner "local-exec" {
    command = <<-EOF
      cd ${path.cwd}
      ${self.triggers.command}
    EOF
  }
}
