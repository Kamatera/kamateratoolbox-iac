import os
import sys
import json
import base64
import datetime
import tempfile
import subprocess


def main(rancher_public_ip, ssh_private_key_file):
    job_name = f'vault-export-manual-{round(datetime.datetime.now().timestamp())}'
    print(f"Starting vault export job: {job_name}")
    subprocess.check_call([
        'kubectl', '-n', 'vault', 'create', 'job', '--from=cronjob/vault-export', job_name
    ])
    print(f"Waiting for job to complete")
    subprocess.check_call([
        'kubectl', '-n', 'vault', 'wait', '--for=condition=complete', f'job/{job_name}'
    ])
    pods = json.loads(subprocess.check_output([
        'kubectl', '-n', 'vault', 'get', 'pod', '-l', f'job-name={job_name}', '-o', 'json'
    ]))['items']
    assert len(pods) == 1
    pod_name = pods[0]['metadata']['name']
    filename = None
    for line in subprocess.check_output([
        'kubectl', '-n', 'vault', 'logs', pod_name
    ]).decode().splitlines():
        if line.startswith('Saving export at /opt/backup/'):
            filename = line.strip().split(' ')[-1].split('/')[-1]
    assert filename
    volume_name = json.loads(subprocess.check_output([
        'kubectl', '-n', 'vault', 'get', 'pvc', 'state-db-backup', '-o', 'json'
    ]))['spec']['volumeName']
    volume_path = os.path.join('/mnt', 'storage', f'vault-state-db-backup-{volume_name}', filename)
    passphrase = base64.b64decode(json.loads(subprocess.check_output([
        'kubectl', '-n', 'vault', 'get', 'secret', 'vaultbackup', '-o', 'json'
    ]))['data']['VAULT_EXPORT_ENCRYPTION_PASSWORD'].encode()).decode()
    kube_backend_db_password = base64.b64decode(json.loads(subprocess.check_output([
        'kubectl', '-n', 'terraform', 'get', 'secret', 'state-db', '-o', 'json'
    ]))['data']['POSTGRES_PASSWORD'].encode()).decode()
    with tempfile.TemporaryDirectory() as tmpdir:
        local_path = os.path.join(tmpdir, filename)
        subprocess.check_call([
            'scp', '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null',
            '-i', ssh_private_key_file, f'root@{rancher_public_ip}:{volume_path}', local_path
        ])
        backup_passphrase, backend_db_password = None, None
        for item in json.loads(subprocess.check_output([
            'gpg', '--decrypt', '--batch', '--passphrase', passphrase, local_path
        ])):
            for k, v in item.items():
                if k == 'kv/iac/vault/export':
                    assert backup_passphrase is None
                    backup_passphrase = v['encryption_password']
                elif k == 'kv/iac/terraform/state_db':
                    assert backend_db_password is None
                    backend_db_password = v['backend-db-password']
        assert backup_passphrase == passphrase
        assert backend_db_password == kube_backend_db_password


if __name__ == "__main__":
    main(*sys.argv[1:])
