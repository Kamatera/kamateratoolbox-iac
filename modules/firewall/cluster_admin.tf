resource "kubernetes_namespace" "cluster_admin" {
  metadata {
    name = "cluster-admin"
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "kubernetes_config_map" "ssh_authorized_keys" {
  metadata {
    name = "ssh-authorized-keys"
    namespace = "cluster-admin"
  }
  data = merge(
    {
      SSHKEY_ssh_access_point: var.ssh_pubkey
    },
    { for k, v in var.ssh_additional_authorized_keys : "SSHKEY_${k}" => v }
  )
}
