locals {
  # Build from docker/certbot on Dec 11, 2022
  certbot_image = "ghcr.io/kamatera/kamateratoolbox-iac-certbot:c9b1c1c39f685b662bddfab69b9ce6b976f52b58"
}

resource "null_resource" "certbot" {
  depends_on = [kamatera_server.nfs, kamatera_server.rancher]
  triggers   = {
    command = <<-EOF
      python3 bin/certbot.py "${var.defaults.root_domain}" "${var.defaults.letsencrypt_email}" \
        ${local.certbot_image} \
        ${kamatera_server.nfs.private_ips[0]} \
        ${kamatera_server.rancher.public_ips[0]}
    EOF
    md5 = filemd5("${path.module}/bin/certbot.py")
  }
  provisioner "local-exec" {
    command = <<EOF
      cd ${path.module} &&\
      ${self.triggers.command}
    EOF
  }
}
