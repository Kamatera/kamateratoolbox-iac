module "httpauth" {
  for_each = toset([
    "prometheus",
    "alertmanager"
  ])
  source = "../common/set_httpauth_secret"
  name = each.value
}
