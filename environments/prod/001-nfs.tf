module "nfs" {
  source = "../../modules/nfs"
  name = "${var.name_suffix}-${var.environment_name}2-nfs"
  datacenter_id = var.datacenter_id
  private_network_full_name = module.private_network.full_name
  ssh_pubkey = file("${path.cwd}/${var.ssh_pubkey_file}")
  ssh_private_key_file = "${path.cwd}/${var.ssh_private_key_file}"
  bastion_host = kamatera_server.bastion.public_ips[0]
}
