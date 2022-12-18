data "cloudflare_zone" "default" {
  name = var.root_domain
}

resource "cloudflare_record" "ingress" {
  for_each = {for i, name in local.worker_names : i => kamatera_server.workers[i].public_ips[0]}
  zone_id = data.cloudflare_zone.default.id
  name = var.default_ingress_subdomain
  type = "A"
  value = each.value
  proxied = false
}
