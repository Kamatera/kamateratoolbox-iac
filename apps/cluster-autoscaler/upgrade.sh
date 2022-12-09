#!/usr/bin/env bash

VERSION="${1}"

if [[ -z "${VERSION}" ]]; then
  echo "Usage: $0 <version>"
  exit 1
fi &&\
echo Upgrading Kamatera Cluster Autoscaler to "${VERSION}" &&\
URL="https://raw.githubusercontent.com/Kamatera/rancher-kubernetes/${VERSION}/rancher/cluster-autoscaler.yaml" &&\
echo "# downloaded $(date +%Y-%m-%d) from:" > apps/cluster-autoscaler/install.yaml &&\
echo "#   ${URL}" >> apps/cluster-autoscaler/install.yaml &&\
curl "${URL}" >> apps/cluster-autoscaler/install.yaml &&\
echo OK
