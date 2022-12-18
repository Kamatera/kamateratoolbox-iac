resource "null_resource" "set_certbot_secret" {
  triggers = {
    command = <<-EOF
      if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
        echo "CLOUDFLARE_API_TOKEN is not set"
        exit 1
      fi &&\
      vault kv put -mount=kv iac/cloudflare \
        api_token=$CLOUDFLARE_API_TOKEN
    EOF
  }
  provisioner "local-exec" {
    command = self.triggers.command
  }
}

module "certbot_argocd_sync" {
  depends_on = [null_resource.set_certbot_secret]
  source = "../common/admin_sync_argocd_app"
  domain = "${var.subdomain_prefix}-argocd-grpc.${var.root_domain}"
  app_name = "certbot"
}

resource "null_resource" "test_certbot" {
  depends_on = [module.certbot_argocd_sync]
  triggers = {
    command = <<-EOF
      JOB_NAME=certbot-manual-$(date +%s)
      echo JOB_NAME=$JOB_NAME &&\
      kubectl -n certbot create job --from=cronjob/certbot $JOB_NAME &&\
      kubectl -n certbot wait --for=condition=complete job/$JOB_NAME &&\
      POD_NAME=$(kubectl -n certbot get pod -l job-name=$JOB_NAME -o json | jq -r '.items[0].metadata.name') &&\
      echo POD_NAME=$POD_NAME &&\
      LOGS="$(kubectl -n certbot logs $POD_NAME)" &&\
      echo "$LOGS" &&\
      echo "$LOGS" | grep "Certificate not yet due for renewal" &&\
      echo "$LOGS" | grep "No renewals were attempted." &&\
      echo "$LOGS" | grep "/etc/letsencrypt/live/${var.root_domain}/fullchain.pem expires on " &&\
      echo "$LOGS" | grep "No change to secret"
    EOF
  }
  provisioner "local-exec" {
    command = self.triggers.command
  }
}
