#!/usr/bin/env python3
"""Install Khan's python2."""

import argparse
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--force", help="Force install of Khan's python2",
                    action="store_true")
args = parser.parse_args()

which = subprocess.run(['which', 'python2'], capture_output=True, text=True)
if which.stdout.strip() != "/usr/bin/python2":
    print("Already running a non-system python2.")
    if not args.force:
        sys.exit(0)

print("Installing python2 from khan/repo. This may take a few minutes.")
subprocess.run(['brew', 'install', 'khan/repo/python@2'], check=True)
