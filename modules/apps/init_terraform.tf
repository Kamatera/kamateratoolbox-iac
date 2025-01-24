resource "null_resource" "terraform_init" {
  triggers = {
    command = <<-EOF
      TEMPDIR=$(mktemp -d) &&\
      cd $TEMPDIR &&\
      BACKEND_DB_PASSWORD=$(pwgen -s 32 1) &&\
      openssl req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key -subj "/CN=terraform-state-db.localhost" &&\
      export VAULT_TOKEN="$(kubectl -n kube-system get secret vault -o jsonpath='{.data.root_token}' | base64 -d)" &&\
      export VAULT_ADDR="https://${var.subdomain_prefix}-vault.${var.root_domain}" &&\
      vault kv put -mount=kv iac/terraform/state_db \
        backend-db-password=$BACKEND_DB_PASSWORD \
        state_db_server.key="$(cat server.key)" \
        state_db_server.crt="$(cat server.crt)"
      RET=$?
      rm -rf $TEMPDIR
      exit $RET
    EOF
  }
  provisioner "local-exec" {
    command = self.triggers.command
  }
  lifecycle {
    ignore_changes = all
  }
}
