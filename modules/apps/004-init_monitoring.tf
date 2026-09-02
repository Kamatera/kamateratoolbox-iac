# resource "null_resource" "set_sendgrid_vault_secret" {
#   triggers = {
#     command = <<-EOF
#       if [ -z "$SENDGRID_USER" ] || [ -z "$SENDGRID_PASSWORD" ] || [ -z "$SENDGRID_FROM_ADDRESS" ]; then
#         echo "SENDGRID_USER, SENDGRID_PASSWORD, and SENDGRID_FROM_ADDRESS env vars must be set"
#         exit 1
#       fi &&\
#       vault kv put -mount=kv iac/sendgrid \
#         user=$SENDGRID_USER \
#         password=$SENDGRID_PASSWORD \
#         from_address=$SENDGRID_FROM_ADDRESS
#     EOF
#   }
#   provisioner "local-exec" {
#     command = self.triggers.command
#   }
# }

module "monitoring_httpauth" {
  for_each = toset([
    "prometheus",
    "alertmanager"
  ])
  source = "../common/set_httpauth_secret"
  name = each.value
}

resource "null_resource" "set_grafana_admin_password" {
  triggers = {
    v = "1"
    command = <<-EOF
      if ! PASSWORD=$(vault kv get -mount=kv -field=admin-password iac/apps/grafana); then
        PASSWORD=$(pwgen -s 32 1)
        vault kv put -mount=kv iac/apps/grafana admin-password=$PASSWORD
      fi &&\
      curl -XPUT -u admin:prom-operator \
        -H "Content-Type: application/json" \
        -d '{"password":"'$PASSWORD'"}' \
        https://grafana.${var.subdomain_prefix}.${var.root_domain}/api/admin/users/1/password
    EOF
  }
  provisioner "local-exec" {
    command = self.triggers.command
  }
}

# I manually created slack contactpoint

resource "null_resource" "set_grafana_default_contactpoint" {
  triggers = {
    v = "2"
    command = <<-EOF
      PASSWORD=$(vault kv get -mount=kv -field=admin-password iac/apps/grafana) &&\
      DOMAIN=grafana.${var.subdomain_prefix}.${var.root_domain} &&\
      ADDRESSES=${var.alert_email_addresses} &&\
      CURL="curl -u admin:$PASSWORD https://$DOMAIN/api/v1" &&\
      $CURL/provisioning/policies -H "Content-Type: application/json" -XPUT \
        -d '{"receiver":"slack"}'
    EOF
  }
  provisioner "local-exec" {
    command = self.triggers.command
  }
}

resource "kubernetes_secret_v1" "monitoring_additional_scrape_configs" {
  metadata {
    name      = "monitoring-additional-scrape-configs"
    namespace = "monitoring"
  }
  data = {
    "additional-scrape-configs.yaml" = <<-EOT
- job_name: external-nodes
  static_configs:
    - targets:
        - ${var.nfs_private_ip}:9100
      labels:
        instance: nfs
    - targets:
        - ${var.bastion_private_ip}:9100
      labels:
        instance: bastion
EOT
  }
}

resource "terraform_data" "install_node_exporter" {
  for_each = toset(["cloudcliprod2-nfs", "cloudcliprod2-bastion"])
  triggers_replace = {
    command = <<-EOF
ssh ${each.key} "
set -euo pipefail
apt update
apt install -y prometheus-node-exporter
"
EOF
  }
  provisioner "local-exec" {
    command = self.triggers_replace.command
    interpreter = ["bash", "-c"]
  }
}
