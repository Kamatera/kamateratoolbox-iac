module "vault_argocd_sync" {
  source = "../common/admin_sync_argocd_app"
  domain = "${var.subdomain_prefix}-argocd-grpc.${var.root_domain}"
  app_name = "vault"
  post_sync_script = <<-EOF
    sleep 5
  EOF
}

resource "null_resource" "vault_init" {
  triggers = {
    command = "python3 vault_init.py https://${var.subdomain_prefix}-vault.${var.root_domain} ${var.initial_admin_user}"
    md5 = md5(file("${path.module}/vault_init.py"))
  }
  provisioner "local-exec" {
    command = <<-EOF
      ${var.set_context} &&\
      cd ${path.module} &&\
      ${self.triggers.command}
    EOF
  }
}

resource "null_resource" "test_vault_backup" {
  depends_on = [null_resource.terraform_init]
  triggers = {
    command = "python3 test_vault_backup.py ${var.rancher_public_ip} ../../${var.ssh_private_key_file}"
    md5 = md5(file("${path.module}/test_vault_backup.py"))
  }
  provisioner "local-exec" {
    command = "${var.set_context} && cd ${path.module} && ${self.triggers.command}"
  }
}

resource "null_resource" "set_env_vars_in_vault" {
  depends_on = [null_resource.vault_init]
  triggers = {
    command = <<-EOF
      ${var.set_context} &&\
      BACKEND_CONN_PASSWORD=$(kubectl -n terraform get secret state-db -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode) &&\
      export VAULT_TOKEN="$(kubectl -n kube-system get secret vault -o jsonpath='{.data.root_token}' | base64 -d)" &&\
      export VAULT_ADDR="https://${var.subdomain_prefix}-vault.${var.root_domain}" &&\
      vault kv put -mount=kv iac/terraform/tf_vars \
        name_suffix=${var.name_suffix} \
        datacenter_id=${var.datacenter_id} \
        rancher_password=${var.rancher_password} \
        letsencrypt_email=${var.letsencrypt_email} \
        root_domain=${var.root_domain} \
        subdomain_prefix=${var.subdomain_prefix} \
        initial_admin_user=${var.initial_admin_user} \
        backend_conn_str=postgres://postgres:$BACKEND_CONN_PASSWORD@${var.ingress_hostname}:9941/postgres
    EOF
  }
  provisioner "local-exec" {
    command = self.triggers.command
  }
}

resource "null_resource" "set_ssh_key_in_vault" {
  depends_on = [null_resource.vault_init]
  triggers = {
    command = <<-EOF
      ${var.set_context} &&\
      export VAULT_TOKEN="$(kubectl -n kube-system get secret vault -o jsonpath='{.data.root_token}' | base64 -d)" &&\
      export VAULT_ADDR="https://${var.subdomain_prefix}-vault.${var.root_domain}" &&\
      vault kv put -mount=kv iac/terraform/ssh_key \
        private_key=@${var.ssh_private_key_file} \
        public_key=@${var.ssh_pubkey_file}
    EOF
  }
    provisioner "local-exec" {
        command = "cd ${path.cwd} && ${self.triggers.command}"
    }
}
