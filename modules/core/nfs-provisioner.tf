resource "null_resource" "deploy_nfs_provisioner" {
  depends_on = [module.set_context, kamatera_server.nfs]
  provisioner "local-exec" {
    command = <<-EOF
      helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ &&\
      helm install -n kube-system nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
        --set nfs.server=${kamatera_server.nfs.private_ips[0]} --set nfs.path=/storage \
        --set storageClass.defaultClass=true \
        --set storageClass.accessModes={ReadWriteOnce,ReadWriteMany}
    EOF
  }
}
