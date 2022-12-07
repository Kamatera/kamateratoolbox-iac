#!/usr/bin/env python3
import os
import sys
import subprocess


def main(root_domain, subdomain_prefix):
    print("Deploying ArgoCD...")
    if subprocess.call(['kubectl', 'get', 'ns', 'argocd']) != 0:
        subprocess.check_call(['kubectl', 'create', 'ns', 'argocd'])
    for template_name in [
        'argocd-cm',
        'argocd-server-https-ingress',
        'argocd-server-grpc-ingress',
    ]:
        with open(os.path.join(os.path.dirname(__file__), f'{template_name}.template.yaml')) as f:
            template = f.read()
            for k, v in {
                'SUBDOMAIN_PREFIX': subdomain_prefix,
                'ROOT_DOMAIN': root_domain,
            }.items():
                template = template.replace(f'__{k}__', v)
        subprocess.run(['kubectl', 'apply', '-n', 'argocd', '-f', '-'], check=True, input=template.encode())
    subprocess.check_call(['kubectl', 'apply', '-n', 'argocd', '-k', 'apps/argocd'])
    print("OK")


if __name__ == '__main__':
    main(*sys.argv[1:])
