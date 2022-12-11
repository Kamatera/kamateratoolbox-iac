resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = <<-EOF
      cp ~/.kube/config ~/.kube/config.$(date +%Y-%m-%d-%H-%M-%S).bak &&\
      TEMPFILE=$(mktemp) &&\
      echo '${rancher2_cluster.cloudcli.kube_config}' > $TEMPFILE &&\
      KUBECONFIG="$TEMPFILE:~/.kube/config" kubectl config view --flatten \
          > ~/.kube/config.new &&\
      mv ~/.kube/config.new ~/.kube/config &&\
      rm $TEMPFILE
    EOF
  }
}

module "set_context" {
  source = "../common/set_kubernetes_context"
  context_name = "cloudcli"
}

resource "null_resource" "check_kuberenetes" {
  depends_on = [module.set_context]
  provisioner "local-exec" {
    command = <<-EOF
      if [ "$(kubectl config current-context)" != "cloudcli" ]; then
        echo "Kubernetes context is not set to cloudcli"
        exit 1
      fi
      if ! kubectl get nodes; then
        echo "Kubernetes cluster is not reachable"
        exit 1
      fi
      echo "Kubernetes cluster is reachable"
    EOF
  }
}
