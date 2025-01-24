resource "null_resource" "deploy_nfs_provisioner" {
  triggers = {
    v = "1"
  }
  provisioner "local-exec" {
    command = <<-EOF
      ${var.set_context} &&\
      helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ &&\
      helm install -n kube-system nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
        --set nfs.server=${var.nfs_private_ip} --set nfs.path=/storage/k3s \
        --set storageClass.defaultClass=true \
        --set storageClass.accessModes={ReadWriteOnce,ReadWriteMany}
    EOF
  }
}
