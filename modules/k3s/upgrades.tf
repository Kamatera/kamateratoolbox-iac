# upgrades should run manually according to k3s documentation
# https://docs.k3s.io/upgrades/manual

# following outputs should be updated after each upgrade

output "controlplane_upgrade_command" {
  value = <<-EOF
      curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.31.4+k3s1 sh -s - \
        --node-name ${local.controlplane_name} \
        --node-ip ${local.controlplane_private_ip} \
        --node-external-ip ${local.controlplane_public_ip} \
        --advertise-address ${local.controlplane_private_ip} \
        --tls-san 0.0.0.0 --tls-san ${local.controlplane_private_ip} --tls-san ${local.controlplane_public_ip} \
        --cluster-init
  EOF
}

output "workers_upgrade_command" {
  value = {
    for worker in toset(["worker1", "worker2", "worker3"]) : worker => <<-EOF
      curl -sfL https://get.k3s.io | K3S_URL=https://${local.controlplane_private_ip}:6443 K3S_TOKEN=${local.k3s_token} sh -s - \
        --node-name ${kamatera_server.k3s[worker].name} \
        --node-ip ${kamatera_server.k3s[worker].private_ips[0]} \
        --node-external-ip ${kamatera_server.k3s[worker].public_ips[0]}
    EOF
  }
}
