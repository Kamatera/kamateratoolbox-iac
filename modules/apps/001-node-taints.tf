resource "kubernetes_node_taint" "controlplane_nodes" {
  field_manager = "Terraform_taint_controlplane_nodes"
  for_each = toset(var.controlplane_node_names)
  metadata {
    name = each.value
  }
  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NoExecute"
  }
  lifecycle {
    ignore_changes = [taint]  # this is needed so that it won't remove automatically added taints
  }
}
