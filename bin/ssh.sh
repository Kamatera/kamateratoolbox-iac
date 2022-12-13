#!/usr/bin/env bash
SERVER="${1}"

if [ "${SERVER}" == "rancher" ]; then
  IP="$(bin/terraform.py $ENVIRONMENT_NAME core output -json | jq -r '.core.value.rancher_public_ip')"
elif [ "${SERVER}" == "nfs" ]; then
  IP="$(bin/terraform.py $ENVIRONMENT_NAME core output -json | jq -r '.core.value.nfs_public_ip')"
elif [ "${SERVER}" == "ssh_access_point" ]; then
  IP="$(bin/terraform.py $ENVIRONMENT_NAME core output -json | jq -r '.core.value.ssh_access_point_public_ip')"
elif [ "${SERVER}" == "controlplane" ]; then
  IP="$(bin/terraform.py $ENVIRONMENT_NAME core output -json | jq -r '.core.value.controlplane_ip')"
elif [ "${SERVER}" == "worker1" ]; then
  IP="$(bin/terraform.py $ENVIRONMENT_NAME core output -json | jq -r '.core.value.worker_ips[0]')"
elif [ "${SERVER}" == "worker2" ]; then
  IP="$(bin/terraform.py $ENVIRONMENT_NAME core output -json | jq -r '.core.value.worker_ips[1]')"
elif [ "${SERVER}" == "worker3" ]; then
  IP="$(bin/terraform.py $ENVIRONMENT_NAME core output -json | jq -r '.core.value.worker_ips[2]')"
else
  echo "Usage: bin/ssh.sh <server>"
  echo "Available servers: rancher, nfs, ssh_access_point, controlplane, worker1, worker2, worker3"
  exit 1
fi

exec ssh -i .id_rsa root@$IP ${@:2}
