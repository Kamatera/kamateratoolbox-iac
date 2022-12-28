#!/usr/bin/env bash

SERVER="${1}"
SCRIPT="${2}"

SSH_ACCESS_POINT_IP="$(bin/terraform.py output -raw ssh_access_point_public_ip --root-environment)"

if [ "${SERVER}" == "ssh_access_point" ] || ([ "${SERVER}" == "" ] && [ "${SCRIPT}" == "" ]); then
  exec ssh -i "${TF_VAR_ssh_private_key_file}" root@$SSH_ACCESS_POINT_IP "${SCRIPT}"
else
  exec ssh -ti "${TF_VAR_ssh_private_key_file}" root@$SSH_ACCESS_POINT_IP "ssh $SERVER '${SCRIPT}'"
fi
