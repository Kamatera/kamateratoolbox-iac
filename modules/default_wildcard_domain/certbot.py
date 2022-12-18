#!/usr/bin/env python3
import os
import sys
import subprocess
from textwrap import dedent


CLOUDFLARE_API_TOKEN = os.environ.get("CLOUDFLARE_API_TOKEN")


def main(root_domain, letsencrypt_email, certbot_image, nfs_private_ip, rancher_public_ip, ssh_private_key_file):
    assert CLOUDFLARE_API_TOKEN
    sshargs = [
        "ssh", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null",
        "-i", ssh_private_key_file, "root@{}".format(rancher_public_ip)
    ]
    subprocess.check_call([
        *sshargs, dedent(f'''
          if cat /etc/fstab | grep -q /mnt/storage; then 
            echo "NFS already mounted"; 
          else
            apt-get update &&\
            apt-get install -y nfs-common &&\
            mkdir /mnt/storage &&\
            echo "{nfs_private_ip}:/storage/ /mnt/storage nfs defaults 0 0" >> /etc/fstab &&\
            mount -a
          fi
        ''')
    ])
    subprocess.check_call([
        *sshargs, dedent(f'''
          docker pull {certbot_image} &&\
          docker run --rm --name certbot \
            -v "/mnt/storage/certbot-{root_domain}/etc_letsencrypt:/etc/letsencrypt" \
            -v "/mnt/storage/certbot-{root_domain}/var_lib_letsencrypt:/var/lib/letsencrypt" \
            -e "CLOUDFLARE_API_TOKEN={CLOUDFLARE_API_TOKEN}" \
            --entrypoint certbot_.py \
            "{certbot_image}" "{root_domain}" "{letsencrypt_email}" --skip-kubectl --renew
        ''')
    ])
    subprocess.check_call([
        *sshargs, dedent(f'''
          if cat /usr/local/bin/rancher_start | grep -q {root_domain}; then
            echo "Rancher start script already configured";
          else
            cp /usr/local/bin/rancher_start /usr/local/bin/rancher_start.$(date +%Y-%m-%d).bak &&\
            sed -i "s;/etc/letsencrypt/live/"'$'"(cat /etc/rancher/domain);/mnt/storage/certbot-{root_domain}/etc_letsencrypt/live/{root_domain};g" /usr/local/bin/rancher_start &&\
            docker stop rancher &&\
            rancher_start
          fi          
        ''')
    ])


if __name__ == "__main__":
    main(*sys.argv[1:])
