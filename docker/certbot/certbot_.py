#!/usr/bin/env python3
import os
import sys
import json
import base64
import tempfile
import subprocess
from textwrap import dedent


def process(root_domain, letsencrypt_email, renew):
    with tempfile.TemporaryDirectory() as tmpdir:
        cloudflare_credentials_ini = os.path.join(tmpdir, 'cloudflare.ini')
        with open(cloudflare_credentials_ini, 'w') as f:
            f.write(dedent(f'''\
                dns_cloudflare_api_token = {os.environ['CLOUDFLARE_API_TOKEN']}
            ''').strip())
        subprocess.check_call(['chmod', '400', cloudflare_credentials_ini])
        subprocess.check_call([
            'certbot', 'certonly', '-d', f'*.{root_domain}',
            '--dns-cloudflare', '--dns-cloudflare-credentials', cloudflare_credentials_ini,
            '--preferred-challenges', 'dns',
            '-m', letsencrypt_email, '--agree-tos', '-n',
        ])
    certs_path = f'/etc/letsencrypt/live/{root_domain}'
    if renew:
        subprocess.check_call([
            'kubectl', '-n', 'ingress-nginx', 'delete', 'secret', 'cloudcli-default-ssl',
        ])
    subprocess.check_call([
        'kubectl', '-n', 'ingress-nginx', 'create', 'secret', 'tls', 'cloudcli-default-ssl',
        '--cert', f'{certs_path}/fullchain.pem',
        '--key', f'{certs_path}/privkey.pem'
    ])


def get_certificate_expiry_days():
    p = subprocess.run([
        "kubectl", "-n", "ingress-nginx", "get", "secret", "cloudcli-default-ssl", "-ojsonpath={.data}"
    ], stdout=subprocess.PIPE)
    if p.returncode == 1:
        return None
    crt = json.loads(p.stdout)['tls.crt']
    datestr = '='.join(subprocess.check_output([
        "openssl", "x509", "-noout", "-enddate"
    ], input=base64.b64decode(crt)).decode().split("=")[1:])
    datets = int(subprocess.check_output(["date", "-d", datestr, "+%s"]).decode().strip())
    nowts = int(subprocess.check_output(["date", "+%s"]).decode().strip())
    return (datets - nowts) / 86400


def main(root_domain, letsencrypt_email, *args):
    renew = "--renew" in args
    cert_expiry_days = get_certificate_expiry_days()
    if cert_expiry_days is not None:
        if not renew:
            print("ERROR! Secret already exists, will not re-create, certificate renewal is handled from an in-cluster cronjob")
            exit(1)
        if cert_expiry_days > 10:
            print("Certificate is still valid, will not renew")
            exit(0)
        process(root_domain, letsencrypt_email, renew=True)
    else:
        process(root_domain, letsencrypt_email, renew=False)


if __name__ == '__main__':
    main(*sys.argv[1:])
