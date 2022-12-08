#!/usr/bin/env python3
import sys
import json
import subprocess


def get_secret(path):
    try:
        return json.loads(subprocess.check_output(["vault", "kv", "get", "-format=json", "-mount=kv", path]))
    except:
        return None


def generate_username_password():
    return (
        subprocess.check_output(["pwgen", "-1", "6"]).decode().strip(),
        subprocess.check_output(["pwgen", "-1", "10"]).decode().strip(),
    )


def get_httpauth_value(password):
    res = subprocess.check_output(["htpasswd", "-nb", "___", password]).decode().strip()
    return res.replace("___:", "")


def main(name):
    secret_name = f'iac/apps/httpauth/{name}'
    if get_secret(secret_name):
        print(f"Secret already exists at Vault path '{secret_name}', will not re-create")
    else:
        print("Creating secret at Vault path '{secret_name}'")
        username, password = generate_username_password()
        subprocess.check_call([
            "vault", "kv", "put", "-mount=kv", secret_name,
            f"username={username}", f"password={password}",
            f"httpauth_password={get_httpauth_value(password)}"
        ])
    print("OK")


if __name__ == '__main__':
    main(*sys.argv[1:])
