module "apps" {
  source = "../../modules/apps"
  admin_kubeconfig_path = module.private.data.admin_kubeconfig_path
  controlplane_node_names = module.rke2.controlplane_node_names
  letsencrypt_email = var.letsencrypt_email
  nfs_private_ip = module.nfs.private_ip
  nfs_public_ip = module.nfs.public_ip
  server_public_ips = module.rke2.server_public_ips
  ssh_private_key_file = var.ssh_private_key_file
  root_domain = module.private.data.root_domain
  subdomain_prefix = module.private.data.subdomain_prefix
  worker_public_ips = module.rke2.worker_public_ips
  initial_admin_user = module.private.data.initial_admin_user
  ssh_pubkey = file("${path.cwd}/${var.ssh_pubkey_file}")
  ssh_additional_authorized_keys = jsondecode(var.ssh_additional_authorized_keys_json)
  alert_email_addresses = var.alert_email_addresses
  prometheus_nagios_sender = module.private.data.prometheus_nagios_sender
  bastion_private_ip = kamatera_server.bastion.private_ips[0]
}

output "apps_domain_suffix" {
  value = ".${module.private.data.subdomain_prefix}.${module.private.data.root_domain}"
}
