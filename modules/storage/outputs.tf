output "storage" {
  value = {
    nfs_server_public_ip = kamatera_server.nfs.public_ips[0]
    nfs_server_private_ip = kamatera_server.nfs.private_ips[0]
  }
}
