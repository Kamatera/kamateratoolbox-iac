module "set_kubernetes_context" {
  source       = "../common/set_kubernetes_context"
  context_name = "cloudcli"
}

resource "null_resource" "deploy_nfs_provisioner" {
  depends_on = [module.set_kubernetes_context, kamatera_server.nfs]
  provisioner "local-exec" {
    command = <<-EOF
      helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ &&\
      helm install -n kube-system nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
        --set nfs.server=${kamatera_server.nfs.private_ips[0]} --set nfs.path=/storage
    EOF
  }
}

resource "null_resource" "set_default_storage_class" {
  depends_on = [null_resource.deploy_nfs_provisioner]
  provisioner "local-exec" {
    command = <<-EOF
      kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    EOF
  }
}
