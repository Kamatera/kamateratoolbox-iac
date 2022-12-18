#!/usr/bin/env python3
import os
import sys
import json
import traceback
import subprocess


ROOT_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def evalstr(s):
    return str(s).replace("'", "'\"'\"'").strip()


def _print(msg):
    msg = evalstr(msg)
    print(f"echo '{msg}'")


def set_vars_from_vault(private_ssh_key_path, public_ssh_key_path, vault_addr, vault_token, sub_environment_name=None):
    vault_kv_path = f'iac/terraform/tf_vars'
    if sub_environment_name:
        vault_kv_path = f'{vault_kv_path}_{sub_environment_name}'
    print(f"echo -n 'Setting tf_vars from Vault ({vault_kv_path}): '")
    env = {
        **os.environ,
        'VAULT_ADDR': vault_addr,
        'VAULT_TOKEN': vault_token,
    }
    for k, v in json.loads(subprocess.check_output([
        'vault', 'kv', 'get', '-mount=kv', '-format=json', vault_kv_path
    ], env=env))['data'].items():
        print(f"export TF_VAR_{k}={evalstr(v)}")
        print(f'echo -n "TF_VAR_{k} "')
    _print("")
    if not os.path.exists(private_ssh_key_path):
        vault_ssh_kv_path = f'iac/terraform/ssh_key'
        p = subprocess.run([
            'vault', 'kv', 'get', '-mount=kv', '-format=json', vault_ssh_kv_path
        ], env=env, stdout=subprocess.PIPE)
        if p.returncode == 0:
            _print(f"Missing ssh key, copying from Vault ({vault_ssh_kv_path})...")
            data = json.loads(p.stdout)['data']
        else:
            raise Exception("Missing ssh key, and Vault key not found")
        with open(private_ssh_key_path, 'w') as f:
            f.write(data['private_key'])
        with open(public_ssh_key_path, 'w') as f:
            f.write(data['public_key'])
        subprocess.check_call(['chmod', '400', private_ssh_key_path], stdout=subprocess.DEVNULL)


def set_vars_from_env(environment_name, private_ssh_key_path):
    print("echo -n 'tf_vars set from env vars: '")
    for k, v in os.environ.items():
        if k.startswith('TF_VAR_'):
            print(f'echo -n "{k} "')
    if not os.path.exists(private_ssh_key_path):
        _print("Missing environment ssh key, creating...")
        subprocess.check_call([
            'ssh-keygen', '-t', 'rsa', '-b', '4096',
            '-C', f"{environment_name} ssh key",
            '-f', private_ssh_key_path, '-N', ''
        ], stdout=subprocess.DEVNULL)
        subprocess.check_call(['chmod', '400', private_ssh_key_path], stdout=subprocess.DEVNULL)


def main(*args):
    ret = 0
    environment_name = args[0] if len(args) > 0 else None
    sub_environment_name = args[1] if len(args) > 1 else None
    bootstrap = '--bootstrap' in args
    env_path = os.path.join(ROOT_PATH, 'environments', environment_name)
    env_file = os.path.join(env_path, '.env')
    sub_env_path = os.path.join(env_path, sub_environment_name) if sub_environment_name else None
    if environment_name is None:
        _print("No environment name provided")
        ret = 1
    elif not os.path.exists(env_path):
        _print(f"Invalid environment name, does not match a subdirectory of 'environments/': {environment_name}")
        ret = 1
    elif sub_env_path and not os.path.exists(sub_env_path):
        _print(f"Invalid sub-environment name, does not match a subdirectory of 'environments/{environment_name}/': {sub_environment_name}")
        ret = 1
    elif not os.path.exists(env_file):
        _print(f"Missing environment .env file, you should copy the example env from {env_file}.example")
        _print("to same name without .example suffix and edit it to set the relevant variables")
        ret = 1
    else:
        vault_addr, vault_token = None, None
        with open(env_file) as f:
            for line in f:
                if 'VAULT_ADDR=' in line:
                    vault_addr = line.split('=')[1].strip().strip('"')
                elif 'VAULT_TOKEN=' in line:
                    vault_token = line.split('=')[1].strip().strip('"')
        private_ssh_key_path = os.path.join(env_path, '.id_rsa')
        public_ssh_key_path = f'{private_ssh_key_path}.pub'
        try:
            print(f"echo login to environment {environment_name}{f'/{sub_environment_name}' if sub_environment_name else ''}")
            print(f'source "{env_file}"')
            print(f"export TF_VAR_environment_name={environment_name}")
            print(f"export TF_VAR_sub_environment_name={sub_environment_name if sub_environment_name else '-'}")
            if vault_addr and vault_token:
                set_vars_from_vault(private_ssh_key_path, public_ssh_key_path, vault_addr, vault_token, sub_environment_name)
            elif bootstrap:
                assert not sub_environment_name, "Cannot bootstrap a sub-environment"
                set_vars_from_env(environment_name, private_ssh_key_path)
            else:
                raise Exception("Missing Vault credentials, you should set VAULT_ADDR and VAULT_TOKEN in the environment .env file")
            assert os.path.exists(private_ssh_key_path) and os.path.exists(public_ssh_key_path)
            print("echo -n 'setting ssh key env vars: '")
            print(f'export TF_VAR_ssh_pubkey_file="environments/{environment_name}/.id_rsa.pub"')
            print(f'echo -n "TF_VAR_ssh_pubkey_file "')
            print(f'export TF_VAR_ssh_private_key_file="environments/{environment_name}/.id_rsa"')
            print(f'echo -n "TF_VAR_ssh_private_key_file "')
            _print("")
            if sub_environment_name:
                print(f'kubectl config use-context $(terraform -chdir=environments/{environment_name} output -raw cluster_context)')
            else:
                print('bin/add_kube_context.sh')
        except:
            _print(traceback.format_exc())
            ret = 1
    if ret == 0:
        _print("Great Success!")
    print(f"(exit {ret})")
    print("# ")
    print("# this script should be executed using the following command:")
    print(f'# eval "$(bin/login.py {environment_name or "<environment_name>"} {sub_environment_name or "[sub_environment_name]"})"')
    print("# ")


if __name__ == '__main__':
    main(*sys.argv[1:])
