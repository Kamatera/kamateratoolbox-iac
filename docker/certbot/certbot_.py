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
    cloudflare_credentials_ini = '/etc/letsencrypt/cloudflare.ini'
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


def process(root_domain, letsencrypt_email, secret_name, secret_namespace, renew, html, additional_domains, has_letsencrypt_data):
    if has_letsencrypt_data and renew:
        subprocess.check_call(['certbot', 'renew'])
        print("Successful renewal using certbot")
    elif html:
        register_html(root_domain, letsencrypt_email)
        print("Successful html registration using certbot")
    else:
        register_wildcard_dns(root_domain, letsencrypt_email, additional_domains)
        print("Successful wildcard dns registration using certbot")
    certs_path = f'/etc/letsencrypt/live/{root_domain}'
    if renew:
        data = json.loads(subprocess.check_output(["kubectl", "-n", secret_namespace, "get", "secret", secret_name, "-ojsonpath={.data}"]))
        with open(os.path.join(certs_path, 'fullchain.pem'), 'r') as f:
            cert = f.read()
        with open(os.path.join(certs_path, 'privkey.pem'), 'r') as f:
            key = f.read()
        if (
            data['tls.crt'].strip() == base64.b64encode(cert.strip().encode()).decode().strip()
            and data['tls.key'].strip() == base64.b64encode(key.strip().encode()).decode().strip()
        ):
            print("No change to secret")
            return
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
    has_letsencrypt_data = os.path.exists(f'/etc/letsencrypt/live/{root_domain}')
    if cert_expiry_days is not None:
        if not renew:
            print("ERROR! Secret already exists, will not re-create, certificate renewal is handled from an in-cluster cronjob")
            exit(1)
        if not has_letsencrypt_data and cert_expiry_days > 10:
            print("Certificate is still valid and there is no letsencrypt data in the directory, will not renew to prevent rate limiting")
            exit(0)
        process(root_domain, letsencrypt_email, secret_name, secret_namespace, renew=True, html=html,
                additional_domains=additional_domains, has_letsencrypt_data=has_letsencrypt_data)
    else:
        process(root_domain, letsencrypt_email, secret_name, secret_namespace, renew=False, html=html,
                additional_domains=additional_domains, has_letsencrypt_data=has_letsencrypt_data)


if __name__ == '__main__':
    main(*sys.argv[1:])
