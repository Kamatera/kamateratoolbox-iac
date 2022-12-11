output "core" {
  value = {
    rancher_private_ip = kamatera_server.rancher.private_ips[0]
    rancher_public_ip = kamatera_server.rancher.public_ips[0]
    nfs_private_ip = kamatera_server.nfs.private_ips[0]
    nfs_public_ip = kamatera_server.nfs.public_ips[0]
    rancher_url = "https://${cloudflare_record.rancher.hostname}"
    "controlplane_ip" = kamatera_server.controlplane.public_ips[0]
    "worker_ips" = [for each in kamatera_server.workers : each.public_ips[0]]
    terraform_state_db_ingress_tcp_port = 9941
    default_ingress_hostname = "cloudcli-default-ingress.${var.defaults.root_domain}"
    ssh_access_point_public_ip = kamatera_server.ssh_access_point.public_ips[0]
  }
}
