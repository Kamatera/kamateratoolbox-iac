resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = <<-EOF
      cp $HOME/.kube/config $HOME/.kube/config.$(date +%Y-%m-%d-%H-%M-%S).bak &&\
      TEMPFILE=$(mktemp) &&\
      echo '${rancher2_cluster.cluster.kube_config}' > $TEMPFILE &&\
      KUBECONFIG="$TEMPFILE:$HOME/.kube/config" kubectl config view --flatten \
          > $HOME/.kube/config.new &&\
      mv $HOME/.kube/config.new $HOME/.kube/config &&\
      rm $TEMPFILE
    EOF
  }
}

resource "null_resource" "check_kuberenetes" {
  depends_on = [null_resource.kubeconfig]
  provisioner "local-exec" {
    command = <<-EOF
      kubectl config set-context ${rancher2_cluster.cluster.name} &&\
      if ! kubectl get nodes; then
        echo "Kubernetes cluster is not reachable"
        exit 1
      fi
      echo "Kubernetes cluster is reachable"
    EOF
  }
}

locals {
  set_context = "kubectl config set-context ${rancher2_cluster.cluster.name}"
}