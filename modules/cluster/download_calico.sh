#!/usr/bin/env bash

URL=https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/tigera-operator.yaml
echo "# Do not modify" > modules/cluster/calico-tigera-operator.yaml
echo "# Downloaded from $URL" >> modules/cluster/calico-tigera-operator.yaml
curl -sL $URL \
  >> modules/cluster/calico-tigera-operator.yaml
