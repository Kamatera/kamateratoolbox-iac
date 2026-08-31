module "private_network" {
  source = "../../modules/private_network"
  name = "${var.name_suffix}-${var.environment_name}2"
  datacenter_id = var.datacenter_id
}
