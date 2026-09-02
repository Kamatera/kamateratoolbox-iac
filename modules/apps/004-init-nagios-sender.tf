resource "kubernetes_secret_v1" "nagios_sender_etc" {
  metadata {
    name      = "prometheus-nagios-sender-etc"
    namespace = "monitoring"
  }
  data = {
    "config.yaml": var.prometheus_nagios_sender.config_yaml
    "send_ncsa.cfg": var.prometheus_nagios_sender.send_ncsa_cfg
  }
}

resource "kubernetes_secret_v1" "nagios_sender_env" {
  metadata {
    name      = "prometheus-nagios-sender-env"
    namespace = "monitoring"
  }
  data = var.prometheus_nagios_sender.env
}

resource "terraform_data" "set_nagios_sender_promurl" {
  triggers_replace = {
    command = <<-EOF
      #!/bin/bash
      set -euo pipefail
      USERNAME=$(vault kv get -mount=kv -field=username iac/apps/httpauth/prometheus)
      PASSWORD=$(vault kv get -mount=kv -field=password iac/apps/httpauth/prometheus)
      URL="http://$USERNAME:$PASSWORD@monitoring-kube-prometheus-prometheus:9090/api"
      KUBECONFIG=${var.admin_kubeconfig_path} kubectl create secret -n monitoring prometheus-nagios-sender-promurl \
        "--from-literal=PROM_API_URL=$URL"
    EOF
  }
}
