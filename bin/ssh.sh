#!/usr/bin/env bash

SERVER="${1}"

SSH_ACCESS_POINT_IP="$(bin/terraform.py output -raw ssh_access_point_public_ip)"

if [ "${SERVER}" == "ssh_access_point" ]; then
  exec ssh -i "${TF_VAR_ssh_private_key_file}" root@$SSH_ACCESS_POINT_IP ${@:2}
else
  exec ssh -ti "${TF_VAR_ssh_private_key_file}" root@$SSH_ACCESS_POINT_IP ssh $SERVER ${@:2}
fi
