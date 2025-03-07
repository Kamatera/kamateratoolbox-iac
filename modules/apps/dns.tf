data "cloudflare_zone" "default" {
  name = var.root_domain
}

resource "cloudflare_record" "default_ingress_subdomains" {
  for_each = toset([
    "argocd",
    "vault",
    "grafana",
    "prometheus",
    "alertmanager",
    "jenkins",
    "argo",
  ])
  zone_id = data.cloudflare_zone.default.id
  name = "${var.subdomain_prefix}-${each.value}"
  type = "CNAME"
  value = var.ingress_hostname
  proxied = false
}
