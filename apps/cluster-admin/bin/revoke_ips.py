import sys
import json
import datetime
import subprocess
from textwrap import dedent


def main(ssh_access_point_private_key, ssh_access_point_public_ip):
    allow_ips = {}
    revoke_ips = {}
    print("Getting configmap allowed-ips")
    for k, v in json.loads(subprocess.check_output([
        "kubectl", "-n", "cluster-admin", "get", "configmap", "allowed-ips", "-o", "json"
    ]))['data'].items():
        if k.startswith('ALLOWED_IP_MANUAL_'):
            revoke_ips[k] = v
        else:
            allow_ips[k] = v
    print(f'Found {len(allow_ips)} allowed IPs and {len(revoke_ips)} IPs to revoke')
    if len(revoke_ips) == 0:
        print('No IPs to revoke, exiting')
        exit(0)
    else:
        print("Recreating configmap allowed-ips")
        subprocess.call([
            "kubectl", "-n", "cluster-admin", "delete", "configmap", "allowed-ips"
        ])
        subprocess.run([
            "kubectl", "-n", "cluster-admin", "create", "-f", "-"
        ], input=json.dumps({
            "apiVersion": "v1",
            "kind": "ConfigMap",
            "metadata": {
                "name": "allowed-ips",
                "namespace": "cluster-admin"
            },
            "data": allow_ips
        }).encode(), check=True)
        print("Forcing restart of cluster-admin daemonset")
        subprocess.check_call([
            "kubectl", "patch", "daemonset/cluster-admin",
            "-n", "cluster-admin",
            "--type", "merge",
            "-p", json.dumps({"spec": {"template": {"metadata": {"labels": {"date": str(datetime.datetime.now().timestamp())}}}}})
        ])
        print("Revoking IPs from additional servers using ssh")
        subprocess.check_call([
            "ssh", "-i", ssh_access_point_private_key, f"root@{ssh_access_point_public_ip}", dedent(f'''
                for SERVER in cloudcli-rancher cloudcli-nfs; do
                    echo revoking ips from $SERVER &&\
                    for IP in {' '.join(revoke_ips.values())} ; do
                        ssh root@$SERVER ufw delete allow in from $IP to any
                    done
                done
            ''')
        ])
        print("Great Success!")


if __name__ == '__main__':
    main(*sys.argv[1:])
