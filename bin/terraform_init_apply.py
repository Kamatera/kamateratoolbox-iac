#!/usr/bin/env python3
import os
import subprocess
import sys
import glob


HELP = '''
Iterate over all the environment modules and run terraform init and apply for each one.

Usage: bin/terraform_init_apply.py <environment_name> [--from=<module>] [--to=<module>] [--plan] [--dry-run] [--only-init] [--help] [apply_args..]
'''.strip()


# core modules which will be applied first in this order
# other modules will be applied after these modules in unspecified order
CORE_MODULES = []


def parse_args(args):
    apply_args, from_module, to_module, dry_run, show_help, only_init, plan = [], None, None, False, False, False, False
    for arg in args:
        if arg.startswith('--to='):
            to_module = arg.split('=')[1]
        elif arg.startswith('--from='):
            from_module = arg.split('=')[1]
        elif arg == '--dry-run':
            dry_run = True
        elif arg == '--help':
            show_help = True
        elif arg == '--only-init':
            only_init = True
        elif arg == '--plan':
            plan = True
        else:
            apply_args.append(arg)
    return apply_args, from_module, to_module, dry_run, show_help, only_init, plan


def get_environment_modules(environment_name):
    environment_modules = set()
    for dirname in glob.glob(f'./environments/{environment_name}/*'):
        if os.path.isdir(dirname):
            environment_modules.add(dirname.split('/')[-1])
    return environment_modules


def process_module(environment_name, module, apply_args, dry_run, only_init, plan):
    plan_apply = "plan" if plan else "apply"
    what = 'init' if only_init else f'init and {plan_apply}'
    print(f'Running terraform {what} for {environment_name}/{module} with {plan_apply} args: {apply_args}')
    if not dry_run:
        subprocess.check_call([
            'bin/terraform.py', environment_name, module, 'init'
        ])
        if not only_init:
            subprocess.check_call([
                'bin/terraform.py', environment_name, module, plan_apply, *apply_args
            ])


def main(environment_name, *args):
    apply_args, from_module, to_module, dry_run, show_help, only_init, plan = parse_args(args)
    if show_help:
        print(HELP)
        exit(1)
    environment_modules = get_environment_modules(environment_name)
    got_from_module = from_module is None
    for module in [*CORE_MODULES, *environment_modules.difference(CORE_MODULES)]:
        if module not in environment_modules:
            continue
        if module == from_module:
            got_from_module = True
        if not got_from_module:
            continue
        process_module(environment_name, module, apply_args, dry_run, only_init, plan)
        if module == to_module:
            break


if __name__ == '__main__':
    main(*sys.argv[1:])
