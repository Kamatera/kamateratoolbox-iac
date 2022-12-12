#!/usr/bin/env python3
import sys
import json
import traceback
import subprocess


def evalstr(s):
    return str(s).replace("'", "'\"'\"'").strip()


def _print(msg):
    msg = evalstr(msg)
    print(f"echo '{msg}'")


def main(*args):
    ret = 0
    environment_name = args[0] if len(args) > 0 else None
    print(f"echo login to environment {environment_name}")
    try:
        print("echo -n 'exported env vars: '")
        for k, v in json.loads(subprocess.check_output([
            "vault", "kv", "get", "-mount=kv", "-format=json", "iac/terraform/env"
        ]))['data']['data'].items():
            print(f"export {k}='{evalstr(v)}'")
            print(f'echo -n {k} ')
        _print("")
        tfvars = json.loads(subprocess.check_output([
            "vault", "kv", "get", "-mount=kv", "-format=json", "iac/terraform/default-tfvars"
        ]))['data']['data']['tfvars']
        with open(f'environments/{environment_name}/defaults.terraform.tfvars', 'w') as f:
            f.write(tfvars)
        _print(f"saved default tfvars at 'environments/{environment_name}/defaults.terraform.tfvars'")
    except:
        _print(traceback.format_exc())
        ret = 1
    _print("Great Success!")
    print("# ")
    print("# this script should be executed using the following command:")
    print(f'# eval "$(bin/login.py {environment_name or "<environment_name>"})"')
    print("# ")
    exit(ret)


if __name__ == '__main__':
    main(*sys.argv[1:])
