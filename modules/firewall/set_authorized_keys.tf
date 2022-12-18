module "authorized_keys_ssh_access_point" {
  source = "../common/set_ssh_authorized_keys"
  authorized_keys = var.ssh_additional_authorized_keys
  private_key_file = "${path.cwd}/${var.ssh_private_key_file}"
  ssh_access_point_public_ip = kamatera_server.ssh_access_point.public_ips[0]
  internal_ssh_host_name = ""
}

module "authorized_keys" {
  depends_on = [null_resource.set_ssh_access_point_config_hosts]
  for_each = toset(keys(null_resource.set_ssh_access_point_config_hosts))
  source = "../common/set_ssh_authorized_keys"
  authorized_keys = var.ssh_additional_authorized_keys
  private_key_file = "${path.cwd}/${var.ssh_private_key_file}"
  ssh_access_point_public_ip = kamatera_server.ssh_access_point.public_ips[0]
  internal_ssh_host_name = each.value
}
