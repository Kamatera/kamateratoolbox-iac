output "cloudcli" {
  value = {
    "rancher_url" = local.rancher_url
    "controlplane_ip" = kamatera_server.controlplane.public_ips[0]
    "worker_ips" = [
      kamatera_server.worker.public_ips[0],
      kamatera_server.workers[0].public_ips[0],
      kamatera_server.workers[1].public_ips[0],
    ]
  }
}

output "kubeconfig" {
  value = rancher2_cluster.cloudcli.kube_config
  sensitive = true
}
