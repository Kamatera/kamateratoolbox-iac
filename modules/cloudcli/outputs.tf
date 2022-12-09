output "cloudcli" {
  value = {
    "rancher_server_ip" = kamatera_server.rancher.public_ips[0]
    "rancher_url" = local.rancher_url
    "controlplane_ip" = kamatera_server.controlplane.public_ips[0]
    "worker_ips" = [
      kamatera_server.workers[0].public_ips[0],
      kamatera_server.workers[1].public_ips[0],
      kamatera_server.workers[2].public_ips[0],
    ]
    nodes_startup_script = local.nodes_startup_script
  }
}

output "kubeconfig" {
  value = rancher2_cluster.cloudcli.kube_config
  sensitive = true
}
