terraform {
  required_providers {
    kamatera = {
      source = "Kamatera/kamatera"
    }
  }
}

variable "datacenter_id" {}
variable "name" {}
variable "password" {sensitive = true}
variable "ssh_pubkey" {}
variable "private_network_full_name" {}

data "kamatera_image" "ubuntu" {
  datacenter_id = var.datacenter_id
  os = "Ubuntu"
  code = "20.04 64bit_optimized_updated"
}

resource "kamatera_server" "rancher" {
  name = var.name
  datacenter_id = var.datacenter_id
  cpu_type = "B"
  cpu_cores = 2
  ram_mb = 4096
  disk_sizes_gb = [100]
  billing_cycle = "monthly"
  image_id = data.kamatera_image.ubuntu.id
  startup_script = <<-EOF
    cd /opt
    rm -Rf /opt/installer
    count=0
    while [ $count -lt 3 ]; do
      git clone -b add-rancher-2-6-7 https://github.com/cloudwm/installer
      exitCode=$?
      if [ $exitCode -eq 0 ]; then break; fi
      let count=$count+1
      sleep 20
    done
    if [ $exitCode -ne 0 ]; then exit 1; fi
    cd /opt/installer
    ./installer installer-contrib-rancher-v2.6.7-kamatera.conf
  EOF
  password = var.password
  ssh_pubkey = var.ssh_pubkey
  network {
    name = var.private_network_full_name
  }
  network {
    name = "wan"
  }
}

output "public_ip" {
  value = kamatera_server.rancher.public_ips[0]
}

output "private_ip" {
  value = kamatera_server.rancher.private_ips[0]
}
