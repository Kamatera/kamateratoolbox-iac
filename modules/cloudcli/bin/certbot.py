#!/usr/bin/env python3
import os
import sys
import subprocess


def getpwd():
    return subprocess.check_output(['pwd']).decode().strip()


def main(root_domain, letsencrypt_email):
    pwd = getpwd()
    subprocess.check_call([
        'docker', 'build', '-t', 'certbot', os.path.join(os.path.dirname(__file__), '../../../docker/certbot')
    ])
    cmd = [
        'docker', 'run', '--rm', '--name', 'certbot',
        '-v', f'{pwd}/.data/certbot/etc/letsencrypt:/etc/letsencrypt',
        '-v', f'{pwd}/.data/certbot/var/lib/letsencrypt:/var/lib/letsencrypt',
        '-v', f'{os.environ["HOME"]}/.kube:/root/.kube',
        '-e', 'CLOUDFLARE_API_TOKEN',
        '--entrypoint', 'certbot_.py',
        'certbot', root_domain, letsencrypt_email
    ]
    subprocess.check_call(cmd)


if __name__ == "__main__":
    main(*sys.argv[1:])
