#!/usr/bin/env bash
CLUSTER_CONTEXT=$(bin/terraform.py output -raw cluster_context) &&\
if ! kubectl config get-contexts | grep -q " ${CLUSTER_CONTEXT} "; then
  echo "Adding kube context '${CLUSTER_CONTEXT}'" &&\
  cp ~/.kube/config ~/.kube/config.$(date +%Y-%m-%d-%H-%M-%S).bak &&\
  TEMPFILE=$(mktemp) &&\
  bin/terraform.py output -raw kubeconfig > $TEMPFILE &&\
  KUBECONFIG="$TEMPFILE:$HOME/.kube/config" kubectl config view --flatten \
      > ~/.kube/config.new &&\
  mv ~/.kube/config.new ~/.kube/config &&\
  rm $TEMPFILE
fi &&\
kubectl config use-context $CLUSTER_CONTEXT
