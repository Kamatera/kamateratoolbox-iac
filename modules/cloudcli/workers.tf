resource "kamatera_server" "workers" {
  count = 3
  name = "cloudcli-worker4-${count.index}"
  datacenter_id = var.defaults.datacenter_id
  cpu_type = "B"
  cpu_cores = 4
  ram_mb = 8192
  disk_sizes_gb = [100]
  billing_cycle = "monthly"
  image_id = data.kamatera_image.ubuntu.id
  startup_script = <<-EOF
    mkdir -p /etc/apt/keyrings &&\
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg &&\
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list &&\
    apt-get update &&\
    apt-get install -y "docker-ce=5:20.10.21~3-0~ubuntu-focal" "docker-ce-cli=5:20.10.21~3-0~ubuntu-focal" containerd.io &&\
    docker version &&\
    ${rancher2_cluster.cloudcli.cluster_registration_token[0].node_command} --worker
  EOF
  ssh_pubkey = var.defaults.ssh_pubkey
  network {
    name = "wan"
  }
  network {
    name = var.defaults.private_network_full_name
  }
}
