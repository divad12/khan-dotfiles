#!/bin/sh -eux

# Install packages that Khan Academy developers likely need/want.
# This is equivalent to running linux-setup.sh as root.

# How to test:
# - Comment out functions below (or remove this file from khanbuntu.pkr.hcl)
# - Create a VM with packer and start it up
# - Copy shared-functions.sh & linux-functions.sh to /tmp in VM
# - Run this file manually in the VM and see what breaks, comment things out,etc

# Bail on any errors
set -e

# TODO(ericbrown): Confirm we are root (i.e. khanbuntu.pkr.hcl sudos first)

# We want to do all our work in /tmp so it doesn't stick around.
ROOT=/tmp/home
mkdir -p "${ROOT}"

# Some of our functions are dependent on this, but we don't really clone
# anything during packer builds
REPOS_DIR="${ROOT}/khan"

# derived path location constants
DEVTOOLS_DIR="${REPOS_DIR}/devtools"

# Location where packer provisioning copies shared-functions.sh and
# linux-functions.sh for use with packer provisioning
# (see khanbuntu.pkr.hcl)
SETUP_DIR=/usr/local/var/packer
VAGRANT_UTIL_DIR=${SETUP_DIR}

# Load the functions that do all the real work
. "${VAGRANT_UTIL_DIR}"/shared-functions.sh
. "${VAGRANT_UTIL_DIR}"/linux-functions.sh

install_packages
install_protoc
install_watchman
setup_clock
config_inotify
install_postgresql

# Copy khan profile so it will always load
# TODO(ericbrown): Is there IP in this? If so, do it in Vagrantfile provisioner
# We do this via Vagrantfile provisioning. For now it is better.
#cp ${SETUP_DIR}/.profile.khan /etc/profile.d/khan-profile.sh
#chmod 644 /etc/profile.d/khan-profile.sh

# Create virtual environment
# TODO(ericbrown): Remove linux-functions.sh import (and test!)
su - vagrant
VAGRANT_UTIL_DIR=/usr/local/var/packer
. ${VAGRANT_UTIL_DIR}/shared-functions.sh
. ${VAGRANT_UTIL_DIR}/linux-functions.sh

HOME=/home/vagrant
create_and_activate_virtualenv "${HOME}/.virtualenv/khan27"
