#!/usr/bin/env python3
import os
import sys
import tempfile
import subprocess
from textwrap import dedent


def main(root_domain, letsencrypt_email):
    if subprocess.call([
        'kubectl', '-n', 'ingress-nginx', 'get', 'secret', 'cloudcli-default-ssl'
    ]) == 0:
        print("ERROR! Secret already exists, will not re-create, certificate renewal is not supported yet")
        exit(1)
    else:
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
        subprocess.check_call([
            'kubectl', '-n', 'ingress-nginx', 'create', 'secret', 'tls', 'cloudcli-default-ssl',
            '--cert', f'{certs_path}/fullchain.pem',
            '--key', f'{certs_path}/privkey.pem'
        ])


if __name__ == '__main__':
    main(*sys.argv[1:])
