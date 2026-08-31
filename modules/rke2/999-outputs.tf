output "controlplane_node_names" {
  value = [
    for name, server in var.servers : name if server.role == "controlplane" || server.role == "controlplane1"
  ]
}

output "worker_public_ips" {
    value = {
      for name, server in var.servers : name => local.server_public_ip[name] if server.role == "worker"
    }
}
