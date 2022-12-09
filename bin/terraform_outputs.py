#!/usr/bin/env python3
import sys
import json
import subprocess


def main(environment_name):
    res = {}
    for module in json.loads(subprocess.check_output(["bin/terraform_env_modules.py", environment_name])):
        out = json.loads(subprocess.check_output(["bin/terraform.py", environment_name, module, "output", "-json"]))
        res[module] = {
            k: v["value"] for k, v in out.items() if not v["sensitive"]
        }
    print(json.dumps(res, indent=2))


if __name__ == '__main__':
    main(*sys.argv[1:])
