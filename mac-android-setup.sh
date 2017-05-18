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

# Ensure the Mobile Github repo is cloned.
clone_mobile_repo() {
    if [ ! -d "$REPOS_DIR"/mobile ]; then
        update "Cloning mobile repository..."
        kaclone_repo git@github.com:Khan/mobile "$REPOS_DIR/" --email="$gitmail"
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
        ln -s "$REPOS_DIR"/mobile/android/third-party/style-guide/configs/KhanAcademyAndroid.xml ~/Library/Preferences/AndroidStudio2.2/codestyles/
    fi
}

# Ensure the Android SDK is installed.
install_android_sdk() {
    if [ ! -d "$ANDROID_HOME"/sdk/tools ]; then
        update "Installing Android SDK..."

        brew cask install android-sdk
        link_sdk
    fi

    # Update or install SDK components.
    # Install platform-tools to get adb.
    "$ANDROID_HOME"/sdk/tools/bin/sdkmanager "tools" "platform-tools"
    # Install Build Tools (25.0.2 is necessary to build using gradle).
    "$ANDROID_HOME"/sdk/tools/bin/sdkmanager "build-tools;25.0.2"
    # Install Google Play Services.
    "$ANDROID_HOME"/sdk/tools/bin/sdkmanager "extras;google;google_play_services"

    # Accept all license agreements.
    # TODO(hannah): There doesn't seem to be a great way to accept all of the
    # licenses programmatically, but make this more robust.
    while sleep 1; do echo "y"; done | "$ANDROID_HOME"/sdk/tools/bin/sdkmanager --licenses
}

# Make a symbolic link from the default Homebrew location to $ANDROID_HOME.
link_sdk() {
    if [ ! -d "$ANDROID_HOME"/sdk/ ]; then
        # Create the directory to store the Andrid SDK.
        mkdir -p "$ANDROID_HOME"/sdk

        # Get the directory where Homebrew installed the Android SDK.
        version_dir=`ls /usr/local/Caskroom/android-sdk/ | head -n1`

        ln -s /usr/local/Caskroom/android-sdk/"$version_dir"/* "$ANDROID_HOME"/sdk/
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
install_jdks
clone_mobile_repo
install_android_sdk
install_android_studio
# TODO(hannah): Move the following three functions to shared-functions.sh.
install_yarn
install_watchman
install_react_native_dependencies

update "Done! Complete setup instructions at \
https://sites.google.com/a/khanacademy.org/forge/for-khan-employees/-new-employees-onboard-doc/developer-setup/mobile-setup/android-setup"
