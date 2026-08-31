locals {
  ssh_config_servers = [
  for name, private_ip in module.rke2.server_private_ips : <<EOT
Host ${local.name_prefix}-${name}
  HostName ${private_ip}
  User root
  IdentitiesOnly yes
  IdentityFile ${path.cwd}/${var.ssh_private_key_file}
  ProxyJump ${local.name_prefix}-bastion

EOT
  ]
}


resource "local_file" "ssh_config" {
  filename = module.private.data.ssh_config_path
  content = <<EOT

Host ${local.name_prefix}-bastion
  HostName ${kamatera_server.bastion.public_ips[0]}
  User root
  IdentitiesOnly yes
  IdentityFile ${path.cwd}/${var.ssh_private_key_file}

Host ${local.name_prefix}-nfs
  HostName ${module.nfs.private_ip}
  User root
  IdentitiesOnly yes
  IdentityFile ${path.cwd}/${var.ssh_private_key_file}
  ProxyJump ${local.name_prefix}-bastion

${join("\n", local.ssh_config_servers)}

EOT
}
