#!/usr/bin/env bash

VERSION="${1}"

if [[ -z "${VERSION}" ]]; then
  echo "Usage: $0 <version>"
  exit 1
fi &&\
echo Upgrading ArgoCD to "${VERSION}" &&\
URL="https://raw.githubusercontent.com/argoproj/argo-cd/${VERSION}/manifests/install.yaml" &&\
echo "# downloaded $(date +%Y-%m-%d) from:" > apps/argocd/install.yaml &&\
echo "#   ${URL}" >> apps/argocd/install.yaml &&\
curl "${URL}" >> apps/argocd/install.yaml &&\
echo OK
