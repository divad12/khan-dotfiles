#!/bin/bash
set -e -o pipefail

# This script sets up developers to work on the iOS app and/or test using an
# iOS emulator. This script can only be run on Mac OSs. (iOS development can
# only be done on Macs.)

# Install in $HOME by default, or an alternate destination specified via $1.
ROOT=${1-$HOME}
mkdir -p "$ROOT"

# The directory to which all repositories will be cloned.
REPOS_DIR="$ROOT/khan"

# Load shared setup functions.
. "$REPOS_DIR/devtools/khan-dotfiles/shared-functions.sh"

# Ensure the Mobile Github repo is cloned.
clone_mobile_repo() {
    if [ ! -d "$REPOS_DIR/mobile" ]; then
        update "Cloning mobile repository..."
        kaclone_repo git@github.com:Khan/mobile "$REPOS_DIR/" -p --email="$gitmail"
    fi
}

# Ensure Carthage is installed. Carthage is used to manage some dependencies and
# is required to compile the app.
install_carthage() {
    if ! which carthage ; then
        update "Installing Carthage..."
        brew install carthage
    fi
}

# Yarn is used to manage our react-native dependencies.
install_yarn() {
    if ! which yarn ; then
        update "Installing yarn..."
        brew install yarn
    fi
}

install_watchman() {
    if ! which watchman ; then
        update "Installing watchman..."
        brew install watchman
    fi
}

install_react_native_dependencies() {
    if [ ! -d "$REPOS_DIR/mobile/react-native/node_modules" ]; then
        update "Installing react-native dependencies..."
        (cd "$REPOS_DIR/mobile/react-native"; yarn)
    fi
}

ensure_mac_os  # Function defined in shared-functions.sh.
# TODO(hannah): Ensure setup.sh has already been run.
clone_mobile_repo
install_carthage
# TODO(hannah): Move the following three functions to shared-functions.sh.
install_yarn
install_watchman
install_react_native_dependencies

update "Done! Complete setup instructions at \
https://sites.google.com/a/khanacademy.org/forge/for-khan-employees/-new-employees-onboard-doc/developer-setup/mobile-setup/ios-setup"