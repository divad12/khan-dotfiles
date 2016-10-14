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

# Ensure the iOS Github repo is cloned.
clone_ios_repo() {
    if [ ! -d "$REPOS_DIR/iOS" ]; then
        update "Cloning iOS repository..."
        kaclone_repo git@github.com:Khan/iOS "$REPOS_DIR/" -p --email="$gitmail"
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

ensure_mac_os  # Function defined in shared-functions.sh.
# TODO(hannah): Ensure setup.sh has already been run.
clone_ios_repo
install_carthage

update "Done! Complete setup instructions at \
https://sites.google.com/a/khanacademy.org/forge/for-khan-employees/-new-employees-onboard-doc/developer-setup/mobile-setup/ios-setup"
