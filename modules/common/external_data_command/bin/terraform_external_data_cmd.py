#!/usr/bin/env python3
import sys
import json
import traceback
import subprocess


def main():
    try:
        query = json.load(sys.stdin)
        p = subprocess.run(query['script'], shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    except Exception:
        print(traceback.format_exc(), file=sys.stderr)
        exit(1)
    if p.returncode == 0:
        print(json.dumps({"output": p.stdout.decode()}))
    else:
        print(p.stdout.decode(), file=sys.stderr)
        exit(p.returncode)


if __name__ == "__main__":
    main()
