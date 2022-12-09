#!/usr/bin/env python3
import os
import sys
import json
import base64
import tempfile
import itertools
import subprocess
from textwrap import dedent


def register_html(domain_name, letsencrypt_email):
    subprocess.check_call([
        'certbot', 'certonly', '-d', domain_name,
        '--webroot', '-w', os.environ['WEBROOT_PATH'],
        '-m', letsencrypt_email, '--agree-tos', '-n',
    ])


def register_wildcard_dns(root_domain, letsencrypt_email, additional_domains):
    with tempfile.TemporaryDirectory() as tmpdir:
        cloudflare_credentials_ini = os.path.join(tmpdir, 'cloudflare.ini')
        with open(cloudflare_credentials_ini, 'w') as f:
            f.write(dedent(f'''\
                dns_cloudflare_api_token = {os.environ['CLOUDFLARE_API_TOKEN']}
            ''').strip())
        subprocess.check_call(['chmod', '400', cloudflare_credentials_ini])
        subprocess.check_call([
            'certbot', 'certonly', '-d', f'*.{root_domain}',
            *list(itertools.chain(*[['-d', d] for d in additional_domains])),
            '--dns-cloudflare', '--dns-cloudflare-credentials', cloudflare_credentials_ini,
            '--preferred-challenges', 'dns',
            '-m', letsencrypt_email, '--agree-tos', '-n',
        ])

def process(root_domain, letsencrypt_email, secret_name, secret_namespace, renew, html, additional_domains):
    if html:
        register_html(root_domain, letsencrypt_email)
    else:
        register_wildcard_dns(root_domain, letsencrypt_email, additional_domains)
    certs_path = f'/etc/letsencrypt/live/{root_domain}'
    if renew:
        subprocess.check_call([
            'kubectl', '-n', secret_namespace, 'delete', 'secret', secret_name,
        ])
    subprocess.check_call([
        'kubectl', '-n', secret_namespace, 'create', 'secret', 'tls', secret_name,
        '--cert', f'{certs_path}/fullchain.pem',
        '--key', f'{certs_path}/privkey.pem'
    ])


def get_certificate_expiry_days(secret_name, secret_namespace):
    p = subprocess.run([
        "kubectl", "-n", secret_namespace, "get", "secret", secret_name, "-ojsonpath={.data}"
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
    html = "--html" in args
    secret_name = "cloudcli-default-ssl"
    secret_namespace = "ingress-nginx"
    additional_domains = []
    for arg in args:
        if arg.startswith("--ssl-secret-name="):
            secret_name = arg.split("=")[1]
        elif arg.startswith("--ssl-secret-namespace="):
            secret_namespace = arg.split("=")[1]
        elif arg.startswith("--additional-domain="):
            additional_domains.append(arg.split("=")[1])
    print(f'Updating secret {secret_name} in namespace {secret_namespace} for domain {root_domain}')
    cert_expiry_days = get_certificate_expiry_days(secret_name, secret_namespace)
    if cert_expiry_days is not None:
        if not renew:
            print("ERROR! Secret already exists, will not re-create, certificate renewal is handled from an in-cluster cronjob")
            exit(1)
        if cert_expiry_days > 10:
            print("Certificate is still valid, will not renew")
            exit(0)
        process(root_domain, letsencrypt_email, secret_name, secret_namespace, renew=True, html=html,
                additional_domains=additional_domains)
    else:
        process(root_domain, letsencrypt_email, secret_name, secret_namespace, renew=False, html=html,
                additional_domains=additional_domains)


if __name__ == '__main__':
    main(*sys.argv[1:])
