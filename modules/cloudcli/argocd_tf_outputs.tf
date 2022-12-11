module "argocd_tf_outputs" {
  source = "../common/argocd_tf_outputs"
  data = {
    cloudcli_server_domain = cloudflare_record.cloudcli.hostname
  }
}
