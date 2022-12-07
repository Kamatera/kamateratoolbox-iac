#!/usr/bin/env python3
import sys
import json
import subprocess


def generate_password():
    return subprocess.check_output(["pwgen", "-s", "16", "1"]).decode().strip()


def main(user_name):
    password = generate_password()
    userpass_accesor = json.loads(subprocess.check_output(["vault", "auth", "list", "-format=json"]))['userpass/']['accessor']
    subprocess.check_call([
        "vault", "write", f"auth/userpass/users/{user_name}",
        f'password={password}',
    ])
    subprocess.check_call([
        "vault", "write", "identity/entity",
        f'name=user_{user_name}',
    ])
    entity_id = json.loads(subprocess.check_output([
        "vault", "read", "-format=json", f"identity/entity/name/user_{user_name}"
    ]))["data"]["id"]
    print(f'entity_id: {entity_id}')
    subprocess.check_call([
        "vault", "write", "identity/entity-alias",
        f'name={user_name}', f'canonical_id={entity_id}', f'mount_accessor={userpass_accesor}',
    ])
    print(f"username: {user_name}")
    print(f"password: {password}")


if __name__ == "__main__":
    main(*sys.argv[1:])
