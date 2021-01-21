#!/bin/bash

set -e

# TODO(ericbrown): It seems homebrew installs tools (for xcode12 for us)
#     See https://docs.brew.sh/Installation
# TODO(ericbrown): We only support Catalina (and Big Sur)
# TODO(ericbrown): This does not work for Big Sur
# TODO(ericbrown): Can we just use homebrew's gcc?
# TODO(ericbrown): We are going to start using bottled deps, do we need gcc?
#     Xcode changes in a rather opinionated way.
#     Perhaps we should install homebrew gcc (or clang)
#     Note: Some things in webapp build from source - we need a C compiler

echo
echo "Checking for Apple command line developer tools..."
if ! gcc --version >/dev/null 2>&1 || [ ! -s /usr/include/stdio.h ]; then
    if sw_vers -productVersion | grep -e '^10\.[0-8]$' -e '^10\.[0-8]\.'; then
        echo "Command line tools are *probably available* for your Mac's OS, but..."
        echo "why not upgrade your OS right now?"
        echo "Otherwise, you can always visit developer.apple.com and grab 'em there."
        exit 1
    fi
    if ! gcc --version >/dev/null 2>&1 ; then
        echo "Installing command line developer tools"
        # If enter is pressed before its done, not a big deal, but it'll just loop to the same place.
        echo "You'll want to wait until the xcode install is complete to press Enter again."
        # Also, how did you get this dotfiles repo in 10.9 without
        # git auto-triggering the command line tools install process??
        xcode-select --install
        exec sh ./mac-setup.sh
        # If this doesn't work for you, you can find the most recent
        # version here: https://developer.apple.com/downloads
    fi
    if sw_vers -productVersion | grep -q -e '^10\.14\.' && [ ! -s /usr/include/stdio.h ]; then
        # mac version is Mojave 10.14.*, install SDK headers
        # The file "macOS_SDK_headers_for_macOS_10.14.pkg" is from
        # xcode command line tools install
        if [ -s /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg ]; then
            # This command isn't guaranteed to work. If it fails, just warn
            # the user there may be problems and advise they contact
            # @dev-support if so.
            if sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target / ; then
                echo "macOS_SDK_headers_for_macOS_10.14 installed"
            else
                echo "We're not able to determine if stdio.h is able to be used by compilers correctly on your system."
                echo "Please reach out to @dev-support if you encounter errors indicating this is a problem while building code or dependencies."
                echo "You may be able to get more information about the setup by running ${tty_bold}gcc -v${tty_normal}"
            fi
        else
            echo "Updating your command line tools"
            # If enter is pressed before its done, not a big deal, but it'll just loop to the same place.
            echo "You'll want to wait until the xcode install is complete to press Enter again."
            sudo rm -rf /Library/Developer/CommandLineTools
            xcode-select --install
            exec sh ./mac-setup.sh
        fi
    fi
else
    echo "Great, found gcc! (assuming we also have other recent devtools)"
fi
