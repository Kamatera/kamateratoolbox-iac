resource "null_resource" "deploy_nfs_provisioner" {
  triggers = {
    v = "2"
  }
  provisioner "local-exec" {
    command = <<-EOF
      export KUBECONFIG=${var.admin_kubeconfig_path} &&\
      helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ &&\
      helm install -n kube-system nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
        --set nfs.server=${var.nfs_private_ip} --set nfs.path=/storage/rke2 \
        --set storageClass.defaultClass=true \
        --set storageClass.accessModes={ReadWriteOnce,ReadWriteMany}
    EOF
  }
}


resource "null_resource" "install_nfs_client" {
  for_each = var.server_public_ips
  triggers = {
    command = <<-EOF
      apt-get update && apt-get install -y nfs-common
    EOF
  }
  provisioner "remote-exec" {
    connection {
      host = each.value
      private_key = file("${path.cwd}/${var.ssh_private_key_file}")
    }
    inline = ["#!/bin/bash", self.triggers.command]
  }
}


resource "null_resource" "create_nfs_directory" {
  provisioner "remote-exec" {
    connection {
      host = var.nfs_public_ip
      private_key = file("${path.cwd}/${var.ssh_private_key_file}")
    }
    inline = ["mkdir -p /storage/rke2"]
  }
}
