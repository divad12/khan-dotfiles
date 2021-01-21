#!/bin/bash

# We need elevated permissions for a small subset of setup tasks. Isolate these
# here so that we can test/qa scripts without babysitting them.

# Bail on any errors
set -e

# The directory to which all repositories will be cloned.
ROOT=${1-$HOME}
REPOS_DIR="$ROOT/khan"

# Derived path location constants
DEVTOOLS_DIR="$REPOS_DIR/devtools"

# Load shared setup functions.
. "$DEVTOOLS_DIR"/khan-dotfiles/shared-functions.sh

install_protoc() {
    # If the user has a homebrew version of protobuf installed, uninstall it so
    # we can manually install our own version in /usr/local.
    if brew list --formula | grep -q '^protobuf$'; then
        info "Uninstalling homebrew version of protobuf\n"
        brew uninstall protobuf
    fi

    brew install wget

    # The mac and linux installation process is the same from here on out aside
    # from the platform-dependent zip archive.
    install_protoc_common https://github.com/protocolbuffers/protobuf/releases/download/v3.4.0/protoc-3.4.0-osx-x86_64.zip
}

# TODO(ericbrown): Detect pre-requisites (i.e. brew, etc.)

# Run sudo once at the beginning to get the necessary permissions.
echo "This setup script needs your password to install things as root."
sudo sh -c 'echo Thanks'

"$DEVTOOLS_DIR"/khan-dotfiles/bin/install-mac-homebrew.py

# It used to be we needed to install xcode-tools, now homebrew does this for us
#"$DEVTOOLS_DIR"/khan-dotfiles/bin/install-mac-gcc.sh

install_protoc

# We use java for our google cloud dataflow jobs that live in webapp
# (as well as in khan-linter for linting those jobs)
install_mac_java

"$DEVTOOLS_DIR"/khan-dotfiles/bin/install-mac-apps.sh
