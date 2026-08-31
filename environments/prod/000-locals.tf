locals {
  infra_version = "2"
  name_prefix = "${var.name_suffix}${var.environment_name}${local.infra_version}"
}
