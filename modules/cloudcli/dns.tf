data "cloudflare_zone" "default" {
  name = var.defaults.root_domain
}

resource "cloudflare_record" "cloudcli" {
  zone_id = data.cloudflare_zone.default.id
  name = "cloudcli"
  type = "CNAME"
  value = local.core.default_ingress_hostname
  proxied = false
}
