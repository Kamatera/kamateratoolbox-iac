module "private_network" {
  source = "../../modules/private_network"
  name = "${var.name_suffix}-${var.environment_name}"
  datacenter_id = var.datacenter_id
}

module "nfs" {
  source = "../../modules/nfs"
  name = "${var.name_suffix}-${var.environment_name}-nfs"
  datacenter_id = var.datacenter_id
  private_network_full_name = module.private_network.full_name
  ssh_pubkey = file("${path.cwd}/${var.ssh_pubkey_file}")
  ssh_private_key_file = var.ssh_private_key_file
}

module "apps" {
  source = "../../modules/apps"
  root_domain = var.root_domain
  subdomain_prefix = var.subdomain_prefix
  set_context = "export KUBECONFIG=/etc/kamatera/cloudcli/kubeconfig"
  ingress_hostname = ""
  rancher_public_ip = ""
  rancher_private_ip = ""
  ssh_private_key_file = var.ssh_private_key_file
  nfs_private_ip = module.nfs.private_ip
  initial_admin_user = var.initial_admin_user
  datacenter_id = var.datacenter_id
  letsencrypt_email = var.letsencrypt_email
  name_suffix = var.name_suffix
  rancher_password = var.rancher_password
  ssh_pubkey_file = var.ssh_pubkey_file
  controlplane_public_ip = ""
  alert_email_addresses = var.alert_email_addresses
}

module "firewall" {
  source = "../../modules/firewall"
  hosts = merge(
    {
      nfs: module.nfs.private_ip
      controlplane: module.k3s.controlplane_private_ip
    },
    {
      for i, ip in module.k3s.worker_private_ips : "worker${i+1}" => ip
    }
  )
  ssh_additional_authorized_keys = jsondecode(var.ssh_additional_authorized_keys_json)
  ssh_private_key_file = var.ssh_private_key_file
  datacenter_id = var.datacenter_id
  private_network_full_name = module.private_network.full_name
  ssh_access_point_name = "${var.name_suffix}-${var.environment_name}-ssh-access-point"
  ssh_pubkey = file("${path.cwd}/${var.ssh_pubkey_file}")
}

module "k3s" {
  source = "../../modules/k3s"
  name_prefix = "${var.name_suffix}-${var.environment_name}-k3s"
  datacenter_id = var.datacenter_id
  password = var.rancher_password
  private_network_full_name = module.private_network.full_name
  ssh_pubkey = file("${path.cwd}/${var.ssh_pubkey_file}")
  ssh_private_key_file = var.ssh_private_key_file
  autoscaler_cluster_name = "${var.name_suffix}${var.environment_name}k"
  autoscaler_nodegroup_name = "cc${var.environment_name}kng1"
  autoscaler_nodegroup_name_prefix = "cldcliprodas"
  root_domain = var.root_domain
  default_ingress_subdomain = "${var.name_suffix}-${var.environment_name}-kingress"
}
