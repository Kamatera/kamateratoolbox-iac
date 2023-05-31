"""
This script is used to fix kubeconfig ca-certs, it tries to generate ca-certs for each cluster by trying to fetch them
from the actual ca certs used when connecting to the server.

The script outputs a new kubeconfig file with the ca-certs replaced.

Following requirements are needed:
- python3.8+
- pip install pyOpenSSL==23.2.0 cryptography==39.0.1 ruamel.yaml==0.17.30

Author: Ori Hoch (github.com/OriHoch)
LICENSE: MIT (https://github.com/Kamatera/kamateratoolbox-iac/blob/main/LICENSE)
Script source: https://github.com/Kamatera/kamateratoolbox-iac/blob/main/bin/fix_kubeconfig_ca_certs.py
"""
import os
import sys
import socket
import base64
import traceback
from urllib.parse import urlparse
from OpenSSL import SSL
from ruamel import yaml
from cryptography.hazmat.primitives import serialization


def get_cadata(server):
    url = urlparse(server)
    host = url.hostname
    port = url.port or 443
    cert_chain = []

    def verify_cb(conn, cert, errnum, depth, ok):
        cert_chain.append(cert.to_cryptography())
        return ok

    context = SSL.Context(SSL.TLS_METHOD)
    context.set_default_verify_paths()
    context.set_verify(SSL.VERIFY_NONE, verify_cb)
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((host, port))
    conn = SSL.Connection(context, sock)
    conn.set_connect_state()
    conn.set_tlsext_host_name(host.encode())
    conn.do_handshake()
    conn.shutdown()
    sock.close()
    return base64.b64encode('\n'.join([
        cert.public_bytes(serialization.Encoding.PEM).decode().strip()
        for cert in cert_chain
    ]).encode()).decode()


def main():
    kubeconfig_path = os.environ.get('KUBECONFIG', os.path.expanduser('~/.kube/config'))
    assert os.path.exists(kubeconfig_path), f'kubeconfig file not found at {kubeconfig_path}'
    with open(kubeconfig_path, 'r') as f:
        kubeconfig = yaml.safe_load(f)
    clusters = kubeconfig['clusters']
    for cluster in clusters:
        if cluster.get('cluster', {}).get('server'):
            try:
                cadata = get_cadata(cluster['cluster']['server'])
            except:
                print(f'Failed to get cadata for {cluster["name"]}: {traceback.format_exc()}', file=sys.stderr)
            else:
                cluster['cluster']['certificate-authority-data'] = cadata
    print(yaml.safe_dump(kubeconfig))


if __name__ == '__main__':
    main()
