data "cloudflare_zone" "default" {
  filter = {
    name = var.root_domain
  }
}

resource "cloudflare_dns_record" "ingress" {
  # for_each = {for i, name in toset(["worker4", "worker5", "worker6"]) : i => kamatera_server.k3s[name].public_ips[0]}
  for_each = var.worker_public_ips
  zone_id = data.cloudflare_zone.default.id
  name = var.default_ingress_subdomain
  type = "A"
  content = each.value
  proxied = false
  ttl = 300
}

output "ingress_hostname" {
  value = "${var.default_ingress_subdomain}.${var.root_domain}"
}
