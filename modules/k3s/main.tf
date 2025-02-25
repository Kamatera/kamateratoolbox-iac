terraform {
  required_providers {
    kamatera = {
      source = "Kamatera/kamatera"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

variable "datacenter_id" {}
variable "name_prefix" {}
variable "password" {sensitive = true}
variable "ssh_pubkey" {}
variable "ssh_private_key_file" {}
variable "private_network_full_name" {}
variable "autoscaler_cluster_name" {}
variable "autoscaler_nodegroup_name" {}
variable "autoscaler_nodegroup_name_prefix" {}
variable "root_domain" {}
variable "default_ingress_subdomain" {}

# data "kamatera_image" "ubuntu" {
#   datacenter_id = var.datacenter_id
#   os = "Ubuntu"
#   code = "24.04 64bit"
# }

resource "kamatera_server" "k3s" {
  for_each = toset(["controlplace", "worker1", "worker2", "worker3", "worker4", "worker5", "worker6"])
  name = "${var.name_prefix}-${each.key}"
  datacenter_id = var.datacenter_id
  cpu_type = "B"
  cpu_cores = 4
  ram_mb = 8192
  disk_sizes_gb = [200]
  billing_cycle = "monthly"
  image_id = "EU:6000C29549da189eaef6ea8a31001a34"  # data.kamatera_image.ubuntu.id
  password = var.password
  ssh_pubkey = var.ssh_pubkey
  network {
    name = var.private_network_full_name
  }
  network {
    name = "wan"
  }
}

output "worker_private_ips" {
  value = [for s in kamatera_server.k3s : s.private_ips[0] if s.name != "${var.name_prefix}-controlplace"]
}

locals {
  controlplane_name = kamatera_server.k3s["controlplace"].name
  controlplane_public_ip = kamatera_server.k3s["controlplace"].public_ips[0]
  controlplane_private_ip = kamatera_server.k3s["controlplace"].private_ips[0]
}

output "controlplane_private_ip" {
  value = local.controlplane_private_ip
}

# resource "null_resource" "install_controlplane" {
#   depends_on = [kamatera_server.k3s["controlplace"]]
#   triggers = {
#     command = <<-EOF
#       curl -sfL https://get.k3s.io | sh -s - \
#         --node-name ${local.controlplane_name} \
#         --node-ip ${local.controlplane_private_ip} \
#         --node-external-ip ${local.controlplane_public_ip} \
#         --advertise-address ${local.controlplane_private_ip} \
#         --tls-san 0.0.0.0 --tls-san ${local.controlplane_private_ip} --tls-san ${local.controlplane_public_ip}
#     EOF
#   }
#   provisioner "remote-exec" {
#     connection {
#       host = local.controlplane_public_ip
#       private_key = file("${path.cwd}/${var.ssh_private_key_file}")
#     }
#     inline = ["#!/bin/bash", self.triggers.command]
#   }
# }

module "k3s_token" {
  source = "../common/external_data_command"
  script = "TOKEN=$(ssh cloudcli-prod-ssh-access-point 'ssh root@${local.controlplane_private_ip} cat /var/lib/rancher/k3s/server/node-token') && echo {\\\"token\\\": \\\"$TOKEN\\\"}"
}

locals {
  k3s_token = module.k3s_token.output.token
}

# for new workers, install manually using the upgrades output
# resource "null_resource" "install_workers" {
#   for_each = toset(["worker1", "worker2", "worker3"])
#   depends_on = [kamatera_server.k3s]
#   triggers = {
#     command = <<-EOF
#       curl -sfL https://get.k3s.io | K3S_URL=https://${local.controlplane_private_ip}:6443 K3S_TOKEN=${local.k3s_token} sh -s - \
#         --node-name ${kamatera_server.k3s[each.key].name} \
#         --node-ip ${kamatera_server.k3s[each.key].private_ips[0]} \
#         --node-external-ip ${kamatera_server.k3s[each.key].public_ips[0]}
#     EOF
#   }
#   provisioner "remote-exec" {
#     connection {
#       host = kamatera_server.k3s[each.key].public_ips[0]
#       private_key = file("${path.cwd}/${var.ssh_private_key_file}")
#     }
#     inline = ["#!/bin/bash", self.triggers.command]
#   }
# }

# copy the kubeconfig manually if needed
# resource "null_resource" "kubeconfig" {
#   # depends_on = [null_resource.install_controlplane]
#   triggers = {
#       command = <<-EOF
#         scp -o StrictHostKeyChecking=no -i ${var.ssh_private_key_file} root@${local.controlplane_public_ip}:/etc/rancher/k3s/k3s.yaml /etc/kamatera/cloudcli/kubeconfig
#         sed -i "s/127.0.0.1/${local.controlplane_public_ip}/" /etc/kamatera/cloudcli/kubeconfig
#       EOF
#   }
#   provisioner "local-exec" {
#     command = self.triggers.command
#   }
# }

resource "null_resource" "install_nfs_client" {
  for_each = kamatera_server.k3s
  depends_on = [kamatera_server.k3s]
  triggers = {
    command = <<-EOF
      apt-get update && apt-get install -y nfs-common
    EOF
  }
  provisioner "remote-exec" {
    connection {
      host = each.value.public_ips[0]
      private_key = file("${path.cwd}/${var.ssh_private_key_file}")
    }
    inline = ["#!/bin/bash", self.triggers.command]
  }
}

resource "null_resource" "set_controlplane_node_taints" {
  # depends_on = [null_resource.kubeconfig]
  triggers = {
      command = <<-EOF
          export KUBECONFIG=/etc/kamatera/cloudcli/kubeconfig
          kubectl taint nodes ${local.controlplane_name} node-role.kubernetes.io/controlplane:NoSchedule
      EOF
  }
  provisioner "local-exec" {
    command = self.triggers.command
  }
}
