#!/usr/bin/env bash

set -e -o pipefail

# This file should be sourced from within a Bash-ish shell

install_homebrew_libraries() {
    update "Installing Homebrew dependencies..."
    # The mobile project requires these Homebrew packages
    brew install pkg-config cairo libpng jpeg giflib pango zopfli \
        getsentry/tools/sentry-cli
}

# Ensure the Mobile Github repo is cloned.
clone_mobile_repo() {
    if [ ! -d "$REPOS_DIR/mobile" ]; then
        update "Cloning mobile repository..."
        kaclone_repo git@github.com:Khan/mobile "$REPOS_DIR/" --email="$gitmail"
    fi
}

install_react_native_dependencies() {
    if [ ! -d "$REPOS_DIR/mobile/react-native/node_modules" ]; then
        update "Installing react-native dependencies..."
        (cd "$REPOS_DIR/mobile/react-native"; yarn)
    fi
}
