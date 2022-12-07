#!/usr/bin/env python3
import os
import sys
import json
import subprocess


RANCHER_ACCESS_KEY = os.environ.get('RANCHER_ACCESS_KEY')
RANCHER_SECRET_KEY = os.environ.get('RANCHER_SECRET_KEY')
KAMATERA_NODE_MANAGEMENT_API_CLIENT_ID = os.environ.get('KAMATERA_NODE_MANAGEMENT_API_CLIENT_ID')
KAMATERA_NODE_MANAGEMENT_API_SECRET = os.environ.get('KAMATERA_NODE_MANAGEMENT_API_SECRET')


def main(rancher_url, name, config_json):
    assert RANCHER_ACCESS_KEY and RANCHER_SECRET_KEY
    config = json.loads(config_json)
    subprocess.check_call([
        'curl', '-s', '-u', f'{RANCHER_ACCESS_KEY}:{RANCHER_SECRET_KEY}',
        '-X', 'POST', '-H', 'Accept: application/json',
        '-H', 'Content-Type: application/json',
        f'{rancher_url}/v3/nodetemplates',
        '-d', json.dumps({
            'name': name,
            'kamateraConfig': {
                'apiClientId': KAMATERA_NODE_MANAGEMENT_API_CLIENT_ID,
                'apiSecret': KAMATERA_NODE_MANAGEMENT_API_SECRET,
                'billing': config.get('billing', 'hourly'),
                'cpu': config.get('cpu', '1B'),
                'datacenter': config.get('datacenter', 'EU'),
                'diskSize': config.get('diskSize', '10'),
                'extraDiskSizes': config.get('extraDiskSizes', ''),  # in GB, comma-separated
                'extraSshkey': config.get('extraSshkey', ''),  # public SSH key to add to authorized keys (optional)
                'image': config.get('image', 'ubuntu_server_18.04_64-bit'),
                'privateNetworkIp': config.get('privateNetworkIp', ''),
                'privateNetworkName': config.get('privateNetworkName', ''),
                'ram': config.get('ram', '1024'),
            }
        })
    ])


if __name__ == '__main__':
    main(*sys.argv[1:])