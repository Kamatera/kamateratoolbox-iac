#!/usr/bin/env bash
if [ "${1}" == "" ]; then
    echo "Usage: bin/allow_ip.sh <LABEL> [IP]"
    echo "  LABEL: A short label without special chars or spaces, to identify the IP in the firewall rule, will be used as a configmap key and env var"
    echo "  IP: IP address to allow, if not specified will use your public IP"
    exit 1
else
  LABEL="${1}"
fi
if [ "${2}" == "" ]; then
  IP=$(curl -s http://whatismyip.akamai.com/)
else
  IP="${2}"
fi
echo adding ${IP} to servers via the ssh access point &&\
ssh -i .id_rsa root@$(bin/terraform.py $ENVIRONMENT_NAME core output -json core | jq -r .ssh_access_point_public_ip) "
  echo adding ip to rancher &&\
  ssh root@cloudcli-rancher ufw allow in from $IP to any &&\
  echo adding ip to nfs &&\
  ssh root@cloudcli-nfs ufw allow in from $IP to any
" &&\
echo adding ${IP} to allowed-ips configmap &&\
kubectl patch configmap/allowed-ips \
  -n cluster-admin \
  --type merge \
  -p '{"data":{"'ALLOWED_IP_MANUAL_${LABEL}'":"'${IP}'"}}' &&\
echo forcing update of the cluster-admin daemonset to update the firewall in all cluster nodes &&\
kubectl patch daemonset/cluster-admin \
  -n cluster-admin \
  --type merge \
  -p '{"spec":{"template":{"metadata":{"labels":{"date":"'"$(date +%s)"'"}}}}}' &&\
echo Great Success!
