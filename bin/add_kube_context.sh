#!/usr/bin/env bash
echo Setting "'cloudcli'" Kubernetes context
cp ~/.kube/config ~/.kube/config.$(date +%Y-%m-%d-%H-%M-%S).bak &&\
TEMPFILE=$(mktemp) &&\
vault kv get -mount=kv -field=kubeconfig iac/terraform/kubeconfig > $TEMPFILE &&\
KUBECONFIG="$TEMPFILE:$HOME/.kube/config" kubectl config view --flatten \
    > ~/.kube/config.new &&\
mv ~/.kube/config.new ~/.kube/config &&\
rm $TEMPFILE
echo Great Success!