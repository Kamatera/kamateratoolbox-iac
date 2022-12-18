module "private_network" {
  source = "../../modules/private_network"
  name = "${var.name_suffix}-${var.environment_name}"
  datacenter_id = var.datacenter_id
}

module "rancher" {
  source = "../../modules/rancher"
  name = "${var.name_suffix}-${var.environment_name}-rancher"
  datacenter_id = var.datacenter_id
  password = var.rancher_password
  private_network_full_name = module.private_network.full_name
  ssh_pubkey = file("${path.cwd}/${var.ssh_pubkey_file}")
}

module "nfs" {
  source = "../../modules/nfs"
  name = "${var.name_suffix}-${var.environment_name}-nfs"
  datacenter_id = var.datacenter_id
  private_network_full_name = module.private_network.full_name
  ssh_pubkey = file("${path.cwd}/${var.ssh_pubkey_file}")
  ssh_private_key_file = var.ssh_private_key_file
}

module "domain" {
  source = "../../modules/default_wildcard_domain"
  letsencrypt_email = var.letsencrypt_email
  root_domain = var.root_domain
  ssh_private_key_file = var.ssh_private_key_file
  nfs_private_ip = module.nfs.private_ip
  rancher_public_ip = module.rancher.public_ip
  rancher_a_record_name = "${var.name_suffix}-${var.environment_name}-rancher"
}

module "cluster" {
  source = "../../modules/cluster"
  name = "${var.name_suffix}-${var.environment_name}"
  rancher_url = module.domain.rancher_url
  datacenter_id = var.datacenter_id
  private_network_full_name = module.private_network.full_name
  ssh_pubkey = file("${path.cwd}/${var.ssh_pubkey_file}")
  default_ingress_subdomain = "${var.name_suffix}-${var.environment_name}-ingress"
  root_domain = var.root_domain
  default_ssl_certificate_secret_name = local.default_ssl_certificate_secret_name
  autoscaler_cluster_name = "${var.name_suffix}${var.environment_name}"
  autoscaler_nodegroup_name = "cc${var.environment_name}ng1"
  autoscaler_nodegroup_name_prefix = "${var.name_suffix}-${var.environment_name}-autoscale"
}

module "apps" {
  source = "../../modules/apps"
  root_domain = var.root_domain
  subdomain_prefix = var.subdomain_prefix
  set_context = module.cluster.set_context
  cluster_context = module.cluster.cluster_context
  ingress_hostname = module.cluster.ingress_hostname
  rancher_public_ip = module.rancher.public_ip
  ssh_private_key_file = var.ssh_private_key_file
  default_ssl_certificate_secret_name = local.default_ssl_certificate_secret_name
  nfs_private_ip = module.nfs.private_ip
  initial_admin_user = var.initial_admin_user
  datacenter_id = var.datacenter_id
  letsencrypt_email = var.letsencrypt_email
  name_suffix = var.name_suffix
  rancher_password = var.rancher_password
  ssh_pubkey_file = var.ssh_pubkey_file
  controlplane_public_ip = module.cluster.controlplane_public_ip
  alert_email_addresses = var.alert_email_addresses
}
