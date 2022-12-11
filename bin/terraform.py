#!/usr/bin/env python3
import os
import sys
import subprocess


STATE_DB_CONN_STRING = os.environ.get('STATE_DB_CONN_STRING')


HELP = '''
Run terraform commands in the specified environment and path.

Usage: bin/terraform.py [--help] <environment> <path> <command> [args] [--init] [--no-backend-config]
'''.strip()


def get_init_args(environment_name, path, path_id, no_backend_config, *args):
    # here you will usually add -backend-config=KEY=VALUE arguments to be initialized
    # if no_backend_config is True, then the backend config arguments should not be added to allow
    # first time initialization of the backend locally
    if STATE_DB_CONN_STRING and not no_backend_config:
        args = [
            f"-backend-config=conn_str={STATE_DB_CONN_STRING}",
            f"-backend-config=schema_name={'.'.join(path_id.split('.')[1:]).replace('.', '_')}",
            *args,
        ]
    return [*args]


def get_apply_args(environment_name, path, path_id, command, *args):
    # here you will usually add -var=KEY=VALUE arguments to the plan related commands like
    #   'plan', 'apply', 'destroy', 'refresh'
    if STATE_DB_CONN_STRING:
        args = [f'-var=backend_config_conn_str={STATE_DB_CONN_STRING}', *args]
    args = [f'-var=cloudflare_api_token={os.environ.get("CLOUDFLARE_API_TOKEN") or ""}', *args]
    return ['-var-file=../defaults.terraform.tfvars', *args]


def get_other_args(environment_name, path, path_id, command, *args):
    # modify arguments if needed for other commands, usually you will not need to do this
    return [*args]


def check_call(*args, **kwargs):
    try:
        subprocess.check_call(*args, **kwargs)
    except subprocess.CalledProcessError as e:
        exit(e.returncode)


def main(environment_name, path, command, *args):
    no_backend_config = '--no-backend-config' in args
    init = '--init' in args
    help = '--help' in args
    args = [arg for arg in args if arg not in ['--no-backend-config', '--init', '--help']]
    if help:
        print(HELP)
        exit(1)
    if init:
        subprocess.check_call([
            'python3', 'bin/terraform.py', environment_name, path, 'init'
        ])
    path = os.path.join('environments', environment_name, path)
    path_id = path.strip().strip('/').replace('/', '.')
    if command == 'init':
        check_call([
            'terraform', f'-chdir={path}', 'init',
            *get_init_args(environment_name, path, path_id, no_backend_config, *args)
        ])
    elif command in ['plan', 'apply', 'destroy', 'refresh', 'import']:
        check_call([
            'terraform', f'-chdir={path}', command,
            *get_apply_args(environment_name, path, path_id, command, *args)
        ])
    else:
        check_call(['terraform', f'-chdir={path}', command, *get_other_args(environment_name, path, path_id, command, *args)])


if __name__ == '__main__':
    main(*sys.argv[1:])
