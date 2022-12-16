#!/usr/bin/env python3
import os
import sys
import json
import tempfile
import subprocess


def kv_list(path):
    return json.loads(subprocess.check_output([
        "vault", "kv", "list", "-format=json", path
    ]))


def kv_list_recursive(path):
    for key in kv_list(path):
        if key.endswith("/"):
            yield from kv_list_recursive(os.path.join(path, key))
        else:
            yield os.path.join(path, key), kv_get(os.path.join(path, key))


def kv_get(path):
    return json.loads(subprocess.check_output([
        "vault", "kv", "get", "-format=json", path
    ]))['data']


def gpg_encrypt_file(source, target, password):
    subprocess.check_call([
        "gpg", "--batch", "--yes", "--passphrase", password, "--symmetric", "--output", target, source
    ])


def main(target_filename):
    with tempfile.TemporaryDirectory() as tmpdir:
        json_filename = os.path.join(tmpdir, "vault.json")
        with open(json_filename, "w") as f:
            print("[", file=f)
            i = 0
            for k, v in kv_list_recursive("kv"):
                if i > 0:
                    print(",", file=f)
                i += 1
                print(json.dumps({k: v}, indent=2), file=f)
            print("]", file=f)
        gpg_encrypt_file(json_filename, target_filename, os.environ["VAULT_EXPORT_ENCRYPTION_PASSWORD"])
    print(f"stored encrypted vault at {target_filename}")
    print(f"you can decrypt it with: gpg --decrypt --passphrase PASS --batch {target_filename}")


if __name__ == "__main__":
    main(*sys.argv[1:])
