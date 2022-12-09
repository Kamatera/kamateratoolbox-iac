#!/usr/bin/env python3
import os
import sys
import glob
import json


# core modules which will be applied first in this order
# other modules will be applied after these modules in unspecified order
CORE_MODULES = [
    "cloudcli",
    "dns",
    "storage",
    "apps",
]


def get_environment_modules(environment_name):
    environment_modules = set()
    for dirname in glob.glob(f'./environments/{environment_name}/*'):
        if os.path.isdir(dirname):
            environment_modules.add(dirname.split('/')[-1])
    for module in [*CORE_MODULES, *environment_modules.difference(CORE_MODULES)]:
        if module not in environment_modules:
            continue
        yield module


def main(environment_name):
    print(json.dumps(list(get_environment_modules(environment_name))))


if __name__ == '__main__':
    main(*sys.argv[1:])
