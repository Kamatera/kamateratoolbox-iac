data "cloudflare_zone" "default" {
  name = var.root_domain
}

resource "cloudflare_record" "cloudcli" {
  zone_id = data.cloudflare_zone.default.id
  name = var.sub_domain
  type = "CNAME"
  value = var.ingress_hostname
  proxied = false
}
