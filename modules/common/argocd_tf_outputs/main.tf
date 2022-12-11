variable "data" {type = map(string)}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "cloudcli"
}

resource "kubernetes_config_map_v1_data" "tf_output" {
  field_manager = "terraform_module_argocd_tf_output"
  metadata {
    name      = "tf-outputs"
    namespace = "argocd"
  }
  data = var.data
}
