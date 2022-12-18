#!/usr/bin/env bash

echo not implemented yet
exit 1

SERVER="${1}"


if [ "${SERVER}" == "rancher" ]; then
  IP="$(bin/terraform.py output -raw rancher_public_ip)"
else
  echo "Usage: bin/ssh.sh <server>"
  echo "Available servers: rancher, nfs, ssh_access_point, controlplane, worker1, worker2, worker3"
  exit 1
fi

exec ssh -i .id_rsa root@$IP ${@:2}
