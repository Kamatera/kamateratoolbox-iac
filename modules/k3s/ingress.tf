data "cloudflare_zone" "default" {
  name = var.root_domain
}

resource "cloudflare_record" "ingress" {
  for_each = {for i, name in toset(["worker4", "worker5", "worker6"]) : i => kamatera_server.k3s[name].public_ips[0]}
  zone_id = data.cloudflare_zone.default.id
  name = var.default_ingress_subdomain
  type = "A"
  value = each.value
  proxied = false
}

output "ingress_hostname" {
  value = values(cloudflare_record.ingress)[0].hostname
}
