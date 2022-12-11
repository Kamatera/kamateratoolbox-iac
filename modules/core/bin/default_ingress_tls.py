#!/usr/bin/env python3
import os
import sys
import tempfile
import subprocess


def get_letsencrypt_file(root_domain, sshargs, filename):
    return subprocess.check_output([
        *sshargs,
        "cat", f"/mnt/storage/certbot-{root_domain}/etc_letsencrypt/live/{root_domain}/{filename}"
    ]).decode().strip()


def main(rancher_public_ip, root_domain):
    if subprocess.call(["kubectl", "-n", "ingress-nginx", "get", "secret", "cloudcli-default-ssl"]) == 0:
        print("Secret already exists, will not recreate")
    else:
        sshargs = [
            "ssh", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null",
            "root@{}".format(rancher_public_ip)
        ]
        with tempfile.TemporaryDirectory() as tmpdir:
            with open(os.path.join(tmpdir, "fullchain.pem"), "w") as f:
                f.write(get_letsencrypt_file(root_domain, sshargs, "fullchain.pem"))
            with open(os.path.join(tmpdir, "privkey.pem"), "w") as f:
                f.write(get_letsencrypt_file(root_domain, sshargs, "privkey.pem"))
            subprocess.check_call([
                'kubectl', '-n', 'ingress-nginx', 'create', 'secret', 'tls', 'cloudcli-default-ssl',
                '--cert', os.path.join(tmpdir, "fullchain.pem"),
                '--key', os.path.join(tmpdir, "privkey.pem")
            ])


if __name__ == "__main__":
    main(*sys.argv[1:])
