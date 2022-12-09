resource "null_resource" "monitoring_get_etcd_certs" {
  triggers = {
    command = <<-EOF
      echo "
      apiVersion: v1
      kind: Secret
      metadata:
        name: etcd-certs
        namespace: monitoring
      data:
        cert: '$(ssh root@${local.cloudcli.controlplane_ip} "cat /etc/kubernetes/ssl/kube-etcd-${replace(local.cloudcli.controlplane_ip, ".", "-")}.pem" | base64 -w0)'
        key: '$(ssh root@${local.cloudcli.controlplane_ip} "cat /etc/kubernetes/ssl/kube-etcd-${replace(local.cloudcli.controlplane_ip, ".", "-")}-key.pem" | base64 -w0)'
        cacert: '$(ssh root@${local.cloudcli.controlplane_ip} "cat /etc/kubernetes/ssl/kube-ca.pem" | base64 -w0)'
      " | kubectl apply -f -
    EOF
  }
  provisioner "local-exec" {
    command = self.triggers.command
  }
}
