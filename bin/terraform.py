#!/usr/bin/env python3
import os
import sys
import subprocess


TF_VAR_environment_name = os.environ.get("TF_VAR_environment_name")
TF_VAR_sub_environment_name = os.environ.get("TF_VAR_sub_environment_name")
TF_VAR_backend_conn_str = os.environ.get('TF_VAR_backend_conn_str')


HELP = '''
Run terraform commands in the current environment (as specified via bin/login.py).

Usage: bin/terraform.py [--help] <command> [args] [--init] [--module=<module>] [--root-environment]
'''.strip()


def get_sub_environment_name():
    if not TF_VAR_sub_environment_name or TF_VAR_sub_environment_name == '-':
        return ''
    else:
        return TF_VAR_sub_environment_name


def get_init_args(*args):
    if TF_VAR_backend_conn_str:
        args = [
            f"-backend-config=conn_str={TF_VAR_backend_conn_str}",
            f"-backend-config=schema_name=kamateratoolboxiactf{get_sub_environment_name()}",
            *args,
        ]
    return [*args]


def get_apply_args(command, *args):
    # here you can add arguments to the plan related commands like
    #   'plan', 'apply', 'destroy', 'refresh'
    return [*args]


def get_other_args(command, *args):
    # modify arguments if needed for other commands, usually you will not need to do this
    return [*args]


def check_call(*args, **kwargs):
    try:
        subprocess.check_call(*args, **kwargs)
    except subprocess.CalledProcessError as e:
        exit(e.returncode)


def main(command, *args):
    assert TF_VAR_environment_name, "Please login first via bin/login.py"
    opts = {}
    for arg in args:
        if arg.startswith('--'):
            if '=' in arg:
                k, v = arg.split('=', 1)
                opts[k[2:]] = v
            else:
                opts[arg[2:]] = True
    args = [arg for arg in args if not arg.startswith('--')]
    if opts.get('help') or command == '--help':
        print(HELP)
        exit(1)
    if opts.get('init'):
        subprocess.check_call([
            'python3', 'bin/terraform.py', 'init'
        ])
    path = os.path.join('environments', TF_VAR_environment_name)
    if get_sub_environment_name() and not opts.get('root-environment'):
        path = os.path.join(path, get_sub_environment_name())
    if command == 'init':
        assert not opts.get('module')
        check_call([
            'terraform', f'-chdir={path}', 'init',
            *get_init_args(*args)
        ])
    elif command in ['plan', 'apply', 'destroy', 'refresh', 'import']:
        if opts.get('module'):
            for arg in args:
                assert not arg.startswith('-target'), 'Cannot use -target with --module'
            args = [
                f'-target=module.{opts["module"]}',
                *args
            ]
        check_call([
            'terraform', f'-chdir={path}', command,
            *get_apply_args(command, *args)
        ])
    else:
        assert not opts.get('module')
        check_call(['terraform', f'-chdir={path}', command, *get_other_args(command, *args)])


if __name__ == '__main__':
    main(*sys.argv[1:])
