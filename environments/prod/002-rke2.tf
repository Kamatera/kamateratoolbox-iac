module "rke2" {
  source = "../../modules/rke2"
  name_prefix = "${var.name_suffix}-${var.environment_name}"
  datacenter_id = var.datacenter_id
  use_existing_private_network_full_name = module.private_network.full_name
  ssh_pubkey = file("${path.cwd}/${var.ssh_pubkey_file}")
  ssh_private_key_file = "${path.cwd}/${var.ssh_private_key_file}"
  rke2_version = module.private.data.rke2_version
  node_token_path = module.private.data.node_token_path
  admin_kubeconfig_path = module.private.data.admin_kubeconfig_path
  servers = {
    controlplane1 = {
      role = "controlplane1"
    }
    controlplane2 = {
      role = "controlplane"
    }
    controlplane3 = {
      role = "controlplane"
    }
    worker1 = {
      role = "worker"
    }
    worker2 = {
      role = "worker"
    }
    worker3 = {
      role = "worker"
    }
  }
}
