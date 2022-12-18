#data "vault_kv_secret_v2" "internal_network_cidr" {
#  mount = vault_mount.kvv2.path
#  name  = vault_kv_secret_v2.test.name
#}
#
#resource "kubernetes_manifest" "calico_global_network_policy" {
#  manifest = {
#    apiVersion: "crd.projectcalico.org/v1"
#    kind: "GlobalNetworkPolicy"
#    metadata: {
#      name: "default"
#    }
#    spec: {
#      ingress: [{action: Allow}]
#      source: {
#        nets: concat(
#
#        )
#      }
#    }
#  }
#}
#
#resource "kubernetes_config_map_v1" "allowed_ips" {
#  depends_on = [kubernetes_namespace.cluster_admin]
#  metadata {
#    name = "allowed-ips"
#    namespace = "cluster-admin"
#  }
#  data = {}
#  lifecycle {
#    ignore_changes = [data]
#  }
#}
#
#locals {
#  default_allowed_ips = merge(
#    {
#      "rancher": kamatera_server.rancher.public_ips[0],
#      "nfs": kamatera_server.nfs.public_ips[0],
#      "ssh_access_point": kamatera_server.ssh_access_point.public_ips[0],
#      "controlplane": kamatera_server.controlplane.public_ips[0],
#    },
#    {
#      for idx, server in kamatera_server.workers : "worker${idx}" => server.public_ips[0]
#    }
#  )
#}
#
#resource "kubernetes_config_map_v1_data" "allowed_ips" {
#  depends_on = [kubernetes_config_map_v1.allowed_ips]
#  metadata {
#    name = "allowed-ips"
#    namespace = "cluster-admin"
#  }
#  data = {
#    for key, value in local.default_allowed_ips : "ALLOWED_IP_${key}" => value
#  }
#}
#
#data "kubernetes_config_map" "allowed_ips" {
#  depends_on = [kubernetes_config_map_v1_data.allowed_ips]
#  metadata {
#    name = "allowed-ips"
#    namespace = "cluster-admin"
#  }
#}
#
#resource "null_resource" "firewall" {
#  depends_on = [kubernetes_config_map_v1_data.allowed_ips]
#  for_each = tomap({
#    "rancher": kamatera_server.rancher.public_ips[0],
#  })
#  triggers = {
#    allowed_ips = join(" ", values(data.kubernetes_config_map.allowed_ips.data))
#  }
#  provisioner "remote-exec" {
#    connection {
#      host = each.value
#      private_key = var.defaults.ssh_private_key
#    }
#    inline = [
#      "#!/bin/bash",
#      <<-EOF
#        ufw --force reset &&\
#        ufw default allow outgoing &&\
#        ufw default deny incoming &&\
#        ufw default deny routed &&\
#        ufw allow in on eth1 &&\
#        for ip in ${self.triggers.allowed_ips}; do
#          ufw allow in from $ip to any
#        done &&\
#        ufw --force enable &&\
#        ufw status verbose
#      EOF
#    ]
#  }
#}
