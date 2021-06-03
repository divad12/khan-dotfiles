#!/usr/bin/env python3
"""Installing Kubernetes related toolings.

Use '--dry' to do try run

Install various tooling such as:
- Docker for Mac
- Skaffold
See https://khanacademy.atlassian.net/wiki/spaces/INFRA/pages/1446085102/Hotel%2BSkaffold%2BBeta%2BInstructions
"""

import time
import sys
import subprocess
import json
import os.path
from pathlib import Path


# Now we edit the custom install for docker config
DOCKER_SETTINGS = os.path.join(
    Path.home(), "Library/Group Containers/group.com.docker/settings.json")
# We checked with IT to ensure that this meets our minimal requirement
# https://khanacademy.slack.com/archives/C0BBDFJ7M/p1615928494029600?thread_ts=1615916359.015100&cid=C0BBDFJ7M
# Update to 8Gb
TARGET_MEMORY = 8192
# Update to 80Gb
TARGET_DISK = 81920
# Enable Kubernetes
TARGET_KUBERNETES = True
# Use 6 CPU
TARGET_CPU = 6


def __check_installed(cmd):
    which = subprocess.run(['which', cmd], capture_output=True)
    return which.returncode == 0


def install_brew_packages(dry_run=False):
    if not __check_installed('docker'):
        print("Installing docker...")
        if not dry_run:
            subprocess.run(
                ['brew', 'install', '-q', '--cask', 'docker'], check=True)
    if not __check_installed('skaffold'):
        print("Installing skaffold...")
        if not dry_run:
            subprocess.run(['brew', 'install', '-q', 'skaffold'], check=True)


def wait_for_setting_file(dry_run=False):
    """Create docker process to setup the setting files.

    From testing we discover that setting file only exists first time we
    start the docker service.  So let's create that!
    https://khanacademy.slack.com/archives/C021LFM76UA/p1622668658023800?thread_ts=1622664454.016800&cid=C021LFM76UA
    """
    if os.path.exists(DOCKER_SETTINGS):
        print("Setting file already exist!")
        return

    print(
        "Starting docker services to wait for '{}'...".format(DOCKER_SETTINGS)
    )
    docker_proc = subprocess.Popen(['open', '/Applications/Docker.app'])
    # wait for 3 mins
    for _ in range(6*3):
        if os.path.exists(DOCKER_SETTINGS):
            break
        print("No settings file found. Retrying...")
        time.sleep(10)
    # Note: this wont actually terminate docker, but that's okay as in the
    # end we will prompt for restart anyway.
    docker_proc.terminate()
    if not os.path.exists(DOCKER_SETTINGS):
        raise RuntimeError(
            "Cannot find setting file: {}. ".format(DOCKER_SETTINGS) +
            "You might need to manually start/restart docker and rerun script."
        )


def update_docker_settings(dry_run=False):
    with open(DOCKER_SETTINGS, 'r') as f:
        json_data = json.load(f)

    # We will update only if you are incresing the value
    # This is intentional as we don't want to reduce existing docker setup for
    # other folks (e.g. district / devops) who might have more intense usage.
    #  e.g. update 1000 -> 2000, False -> True
    settings_update = {
        'memoryMiB': TARGET_MEMORY,
        'diskSizeMiB': TARGET_DISK,
        'kubernetesEnabled': TARGET_KUBERNETES,
        'cpus': TARGET_CPU,
    }
    value_updated = False
    for key, target_value in settings_update.items():
        # Note: some keys might be missing (e.g. kubernetesEnabled)
        value_now = json_data.get(key, 0)
        # HACK: int cast to make it works for bool
        if value_now < int(target_value):
            print("Updating {} from {} to {}".format(
                key, value_now, target_value
            ))
            json_data[key] = target_value
            value_updated = True

    if not value_updated:
        print("No update required for {}".format(DOCKER_SETTINGS))
        return

    updated_json_str = json.dumps(json_data, indent=4)
    if not dry_run:
        with open(DOCKER_SETTINGS, 'w') as f:
            f.write(updated_json_str)
        print(
            "[ACTION REQUIRED] Setting updated - you might need to restart "
            "Docker for Mac"
        )
    else:
        print("Updated data as: {}".format(updated_json_str))


if __name__ == "__main__":
    dry_run = False
    # TODO: argparse if you need to do more!
    if len(sys.argv) > 1 and 'dry' in sys.argv[1]:
        print("Running dry run...")
        dry_run = True
    install_brew_packages(dry_run)
    wait_for_setting_file(dry_run)
    update_docker_settings(dry_run)
