#!/bin/bash

# Bail on any errors
set -e

# TODO(ericbrown): Support --quiet command line argument
# TODO(ericbrown): Use python??

# The directory to which all repositories will be cloned.
ROOT=${1-$HOME}
REPOS_DIR="$ROOT/khan"

# Derived path location constants
DEVTOOLS_DIR="$REPOS_DIR/devtools"

echo
echo "Running Khan Installation Script 1.2"

if ! sw_vers -productVersion 2>/dev/null | grep -q '10\.1[12345]\.' ; then
    echo "Warning: This is only tested up to macOS 10.15 (Catalina)."
    echo
    echo "If you find that this works on a newer version of macOS, "
    echo "please update this message."
    echo
fi

echo "After each statement, either something will open for you to"
echo "interact with, or a script will run for you to use"
echo
echo "Press enter when a download/install is completed to go to"
echo "the next step (including this one)"

if ! echo "$SHELL" | grep -q -e '/bash$' -e '/zsh$' ; then
    echo
    echo "It looks like you're using a shell other than bash or zsh!"
    echo "Other shells are not officially supported.  Most things"
    echo "should work, but dev-support help is not guaranteed."
fi

read -p "Press enter to continue..."

# TODO(ericbrown): Pass command line arguments below
# Note that ensure parsing arguments (above) doesn't hide anything

# Run setup that requires sudo access
"$DEVTOOLS_DIR"/khan-dotfiles/mac-setup-elevated.sh

# Run setup that does NOT require sudo access
"$DEVTOOLS_DIR"/khan-dotfiles/mac-setup-normal.sh
