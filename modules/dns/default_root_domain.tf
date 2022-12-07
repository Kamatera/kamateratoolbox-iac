data "cloudflare_zone" "default" {
  name = var.defaults.root_domain
}

resource "cloudflare_record" "default_ingress" {
  for_each = toset(local.cloudcli.worker_ips)
  zone_id = data.cloudflare_zone.default.id
  name = "cloudcli-default-ingress"
  type = "A"
  value = each.value
  proxied = false
}

resource "cloudflare_record" "default_sub_domains" {
  for_each = toset([
    "argocd",
    "argocd-grpc",
    "vault",
  ])
  zone_id = data.cloudflare_zone.default.id
  name = "cloudcli-${each.value}"
  type = "CNAME"
  value = "cloudcli-default-ingress.${var.defaults.root_domain}"
  proxied = false
}
