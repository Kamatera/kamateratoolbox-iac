resource "kubernetes_manifest" "rke2-canal-helm-chart-config" {
  field_manager {
    force_conflicts = true
  }
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChartConfig"
    metadata = {
      name      = "rke2-canal"
      namespace = "kube-system"
    }
    spec = {
      valuesContent = <<-EOT
        flannel:
          # force internal communication over private network
          # when we setup the servers we ensure that eth1 is the private network interface
          backend: "vxlan"
          iface: "eth1"
      EOT
    }
  }
}
