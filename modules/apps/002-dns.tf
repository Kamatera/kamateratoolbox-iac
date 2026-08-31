data "cloudflare_zone" "default" {
  filter = {
    name = var.root_domain
  }
}

resource "cloudflare_dns_record" "ingress_a_record" {
  for_each = {for server, ip in var.worker_public_ips : server => ip}
  zone_id = data.cloudflare_zone.default.id
  name = "${var.subdomain_prefix}ingress"
  type = "A"
  content = each.value
  proxied = false
  ttl = 300
}

resource "cloudflare_dns_record" "ingress_cname_star" {
  zone_id = data.cloudflare_zone.default.id
  name = "*.${var.subdomain_prefix}"
  type = "CNAME"
  content = "${var.subdomain_prefix}ingress.${var.root_domain}"
  proxied = false
  ttl = 300
}
