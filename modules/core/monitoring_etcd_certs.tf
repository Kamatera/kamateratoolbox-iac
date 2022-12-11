resource "null_resource" "monitoring_get_etcd_certs" {
  depends_on = [module.set_context]
  triggers = {
    command = <<-EOF
      echo "
      apiVersion: v1
      kind: Secret
      metadata:
        name: etcd-certs
        namespace: monitoring
      data:
        cert: '$(ssh root@${kamatera_server.controlplane.public_ips[0]} "cat /etc/kubernetes/ssl/kube-etcd-${replace(kamatera_server.controlplane.public_ips[0], ".", "-")}.pem" | base64 -w0)'
        key: '$(ssh root@${kamatera_server.controlplane.public_ips[0]} "cat /etc/kubernetes/ssl/kube-etcd-${replace(kamatera_server.controlplane.public_ips[0], ".", "-")}-key.pem" | base64 -w0)'
        cacert: '$(ssh root@${kamatera_server.controlplane.public_ips[0]} "cat /etc/kubernetes/ssl/kube-ca.pem" | base64 -w0)'
      " | kubectl apply -f -
    EOF
  }
  provisioner "local-exec" {
    command = self.triggers.command
  }
}
