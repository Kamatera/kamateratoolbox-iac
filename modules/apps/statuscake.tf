data "statuscake_contact_group" "default" {
  id = "289378"
}

# we only need to do an SSL check on one of the subdomains because they all use the same certificate
resource "statuscake_ssl_check" "argocd" {
    check_interval = 86400
    contact_groups = [
        data.statuscake_contact_group.default.id
    ]
    alert_config {
        alert_at = [5, 3, 1]
        on_reminder = true
        on_expiry   = true
        on_broken   = true
        on_mixed    = true
    }
    monitored_resource {
        address = "https://${var.subdomain_prefix}-argocd.${var.root_domain}"
    }
}

resource "statuscake_ssl_check" "cloudcli" {
    check_interval = 86400
    contact_groups = [
        data.statuscake_contact_group.default.id
    ]
    alert_config {
        alert_at = [5, 3, 1]
        on_reminder = true
        on_expiry   = true
        on_broken   = true
        on_mixed    = true
    }
    monitored_resource {
        address = "https://${var.subdomain_prefix}-argocd.${var.root_domain}"
    }
}

resource "statuscake_uptime_check" "apps" {
    for_each = {
        "argocd": "Argo CD",
        "vault": "Vault",
        "grafana": "Grafana",
    }
    name = "cloudcli-prod-${each.key}"
    check_interval = 60
    confirmation = 3
    http_check {
        status_codes = [204, 205, 206, 303, 400, 401, 403, 404, 405, 406, 408, 410, 413, 444, 429, 494, 495, 496, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 521, 522, 523, 524, 520, 598, 599]
        validate_ssl = true
        follow_redirects = true
        timeout = 15
        content_matchers {
            content = each.value
        }
    }
    monitored_resource {
        address = "https://${var.subdomain_prefix}-${each.key}.${var.root_domain}"
    }
    contact_groups = [
        data.statuscake_contact_group.default.id
    ]
}

resource "statuscake_uptime_check" "cloudcli" {
    name = "cloudcli-cloudwm-com"
    check_interval = 60
    confirmation = 3
    http_check {
        status_codes = [204, 205, 206, 303, 400, 401, 403, 404, 405, 406, 408, 410, 413, 444, 429, 494, 495, 496, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 521, 522, 523, 524, 520, 598, 599]
        validate_ssl = true
        follow_redirects = false
        timeout = 15
        content_matchers {
            content = "{\"ready\":true}"
        }
    }
    monitored_resource {
        address = "https://cloudcli.cloudwm.com"
    }
    contact_groups = [
        data.statuscake_contact_group.default.id
    ]
}
