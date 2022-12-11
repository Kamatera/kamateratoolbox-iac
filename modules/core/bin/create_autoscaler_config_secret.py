#!/usr/bin/env python3
import base64
import os
import sys
import json
import subprocess
from textwrap import dedent


KAMATERA_AUTOSCALER_API_CLIENT_ID = os.environ['KAMATERA_AUTOSCALER_API_CLIENT_ID']
KAMATERA_AUTOSCALER_API_SECRET = os.environ['KAMATERA_AUTOSCALER_API_SECRET']


def get_configuration(datacenter_id, image_id, private_network, cpu, ram, disk_size, startup_script_base64, ssh_pubkey):
    # see https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/kamatera/README.md#configuration
    return dedent(f"""
        [global]
        kamatera-api-client-id={KAMATERA_AUTOSCALER_API_CLIENT_ID.strip()}
        kamatera-api-secret={KAMATERA_AUTOSCALER_API_SECRET.strip()}
        cluster-name=cloudcli
        
        [nodegroup "ng1"]
        name-prefix=cloudcling1
        min-size=0
        max-size=3
        datacenter={datacenter_id.strip()}
        image={image_id.strip()}
        network = "name=wan,ip=auto"
        network = "name={private_network.strip()},ip=auto"
        cpu={cpu.strip()}
        ram={ram.strip()}
        disk=size={disk_size.strip()}
        script-base64={startup_script_base64.strip()}
        ssh-key={ssh_pubkey.strip()}
    """).strip()


def main(datacenter_id, image_id, private_network, cpu, ram, disk_size, startup_script_base64, ssh_pubkey):
    p = subprocess.run([
        "kubectl", "apply", "-f", "-"
    ], input=json.dumps({
        "apiVersion": "v1",
        "kind": "Secret",
        "metadata": {
            "name": "cluster-autoscaler-kamatera",
            "namespace": "kube-system",
        },
        "data": {
            "cloud-config": base64.b64encode(get_configuration(datacenter_id, image_id, private_network, cpu, ram, disk_size, startup_script_base64, ssh_pubkey).encode()).decode(),
        },
    }).encode())
    assert p.returncode == 0


if __name__ == "__main__":
    main(*sys.argv[1:])
