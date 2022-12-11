data "cloudflare_zone" "default" {
  name = var.defaults.root_domain
}

resource "cloudflare_record" "rancher" {
  zone_id = data.cloudflare_zone.default.id
  name = "cloudcli-rancher"
  type = "A"
  value = kamatera_server.rancher.public_ips[0]
  proxied = false
}

resource "rancher2_setting" "server_url" {
  name = "server-url"
  value = "https://${cloudflare_record.rancher.hostname}"
}

resource "cloudflare_record" "default_ingress" {
  for_each = toset([for each in kamatera_server.workers : each.public_ips[0]])
  zone_id = data.cloudflare_zone.default.id
  name = "cloudcli-default-ingress"
  type = "A"
  value = each.value
  proxied = false
}

resource "cloudflare_record" "default_ingress_subdomains" {
  for_each = toset([
    "argocd",
    "argocd-grpc",
    "vault",
    "grafana",
    "prometheus",
    "alertmanager",
  ])
  zone_id = data.cloudflare_zone.default.id
  name = "cloudcli-${each.value}"
  type = "CNAME"
  value = "cloudcli-default-ingress.${var.defaults.root_domain}"
  proxied = false
}
