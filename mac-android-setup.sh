#!/bin/bash
set -e -o pipefail

# This script sets up developers to work on the Android app and/or test using an
# Android emulator. As of now, this script can only be run on Mac OSs. (While
# there is support for Android dev on Linux, none of the mobile developers on
# the team have tried it.)

# Install in $HOME by default, or an alternate destination specified via $1.
ROOT=${1-$HOME}
mkdir -p "$ROOT"

# The directory to which all repositories will be cloned.
REPOS_DIR="$ROOT/khan"

# Derived path location constants
DEVTOOLS_DIR="$REPOS_DIR/devtools"
KACLONE_BIN="$DEVTOOLS_DIR/ka-clone/bin/ka-clone"

ANDROID_HOME=~/Library/Android

# Load shared setup functions.
. "$DEVTOOLS_DIR"/khan-dotfiles/shared-functions.sh

# Ensure Java 7 and 8 are installed.
# While Android doesn't support most of the features of Java 8, we use
# retrolambda to give us the features of Java 8 lambdas. This requires 
# developers to have JDK 8 installed and set as their JDK.
install_jdks() {
    # Ensure some version of Java is installed so /usr/libexec/java_home -V
    # doesn't cause an error.
    if ! java -version ; then
        update "Installing Java 7 SDK..."
        brew cask install caskroom/versions/java7
    fi

    # Determine which Java SDKs we have. Note: -V prints to stderr.
    java_versions=$( /usr/libexec/java_home -V 2>&1 )

    if ! echo "$java_versions" | grep -q -e "Java SE 7"; then
        update "Installing Java 7 SDK..."
        brew cask install caskroom/versions/java7
    fi

    if ! echo "$java_versions" | grep -q -e "Java SE 8"; then
        update "Installing Java 8 SDK..."
        brew cask install java
    fi
}

# Ensure the Android Github repo is cloned.
clone_android_repo() {
    if [ ! -d "$REPOS_DIR"/android ]; then
        update "Cloning android repository..."
        kaclone_repo git@github.com:Khan/android "$REPOS_DIR/" -p --email="$gitmail"
    fi
}

# Ensure Android Studio is installed (or that the user does not want to install it).
install_android_studio() {
    if [ ! -e "/Applications/Android Studio.app" ]; then
        # If Android Studio is not installed, ask the user before installing it.
        if [ "$(get_yn_input "Install Android Studio?" "y")" = "y" ]; then
            update "Installing or updating Android Studio..."
            brew cask install android-studio
            configure_codestyle
        fi
    fi
}

# Create a symbolic link to the KA codestyle files so that they can be used by
# Android Studio.
configure_codestyle() {
    mkdir -p ~/Library/Preferences/AndroidStudio2.2/codestyles

    if [ ! -e ~/Library/Preferences/AndroidStudio2.2/codestyles/KhanAcademyAndroid.xml ]; then
        update "Linking KA codestyle files..."
        ln -s "$REPOS_DIR"/android/third-party/style-guide/configs/KhanAcademyAndroid.xml ~/Library/Preferences/AndroidStudio2.2/codestyles/
    fi
}

# Ensure the Android SDK is installed.
install_android_sdk() {
    if [ ! -d "$ANDROID_HOME"/sdk/tools ]; then
        update "Installing Android SDK..."
        
        brew install android-sdk
        link_sdk
    fi

    # Update or install SDK components.
    # Install platform-tools to get adb.
    echo y | android update sdk --no-ui --all --filter "tools","platform-tools"
    # Install Build Tools (23.0.2 is necessary to build using gradle).
    echo y | android update sdk --no-ui --all --filter "build-tools","build-tools-23.0.2"
    # Install Google Play Services.
    echo y | android update sdk --no-ui --all --filter "extra-google-google_play_services"
}

# Make a symbolic link from the default Homebrew location to $ANDROID_HOME.
link_sdk() {
    if [ ! -d "$ANDROID_HOME"/sdk/ ]; then
        # Create the directory to store the Andrid SDK.
        mkdir -p "$ANDROID_HOME"/sdk

        # Get the directory where Homebrew installed the Android SDK.
        version_dir=`ls /usr/local/Cellar/android-sdk/ | head -n1`

        ln -s /usr/local/Cellar/android-sdk/"$version_dir"/* "$ANDROID_HOME"/sdk/
    fi
}

ensure_mac_os  # Function defined in shared-functions.sh.
# TODO(hannah): Ensure setup.sh has already been run.
install_jdks
clone_android_repo
install_android_sdk
install_android_studio

update "Done! Complete setup instructions at \
https://sites.google.com/a/khanacademy.org/forge/for-khan-employees/-new-employees-onboard-doc/developer-setup/mobile-setup/android-setup"
