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
. "$DEVTOOLS_DIR"/khan-dotfiles/mobile-functions.sh

# Ensure Java 7 and 8 are installed.
# While Android doesn't support most of the features of Java 8, we use
# retrolambda to give us the features of Java 8 lambdas. This requires
# developers to have JDK 8 installed and set as their JDK.
install_java8() {
    brew tap caskroom/versions
    brew cask install java8
}

ensure_jdks() {
    # Ensure some version of Java is installed so /usr/libexec/java_home -V
    # doesn't cause an error.
    if ! java -version ; then
        err_and_exit "Could not find any JDKs.\n\nDownload JDK 7 _and_ 8 from Oracle's website, install them both, and then re-run this script."
    fi

    # Determine which Java SDKs we have. Note: -V prints to stderr.
    java_versions=$( /usr/libexec/java_home -V 2>&1 )

    # TODO(Kai): maybe need to remove the chceking of JDK 7 if it is no longer needed.
    if ! echo "$java_versions" | grep -q -e "Java SE 7"; then
        echo "Because Oracle requires a login to install JDK 7, so you have to manually install it from Oracle's website:"
        echo "http://www.oracle.com/technetwork/java/javase/downloads/java-archive-downloads-javase7-521261.html"
    fi

    if ! echo "$java_versions" | grep -q -e "Java SE 8"; then
        echo "Could not find JDK 8.Installing it ..."
        install_java8
    fi
}

# Ensure Android Studio is installed (or that the user does not want to install it).
# This function isn't used; see TODO at the bottom of the file.
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
    mkdir -p ~/Library/Preferences/AndroidStudio3.1/codestyles

    if [ ! -e ~/Library/Preferences/AndroidStudio3.1/codestyles/KhanAcademyAndroid.xml ]; then
        update "Linking KA codestyle files..."
        ln -s "$REPOS_DIR"/mobile/android/third-party/style-guide/configs/KhanAcademyAndroid.xml ~/Library/Preferences/AndroidStudio3.1/codestyles/
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
    # TODO(Kai): For some reason, this way to accept all licenses doesn't work and exits unexpectedly,
    # so temporarily diable it.
    # while sleep 1; do echo "y"; done | "$ANDROID_HOME"/sdk/tools/bin/sdkmanager --licenses
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

ensure_mac_os  # Function defined in shared-functions.sh.
# TODO(hannah): Ensure setup.sh has already been run.
ensure_jdks
clone_mobile_repo
install_android_sdk
# TODO(hannah): We can't use install_android_studio because our app doesn't
# build with the latest version of Android Studio. Uncomment this once we can!
#install_android_studio

install_homebrew_libraries

install_yarn
install_watchman
install_react_native_dependencies

update "Done! Complete setup instructions at \
https://docs.google.com/document/d/1QMMgvycznCezczZojEdAk8WHm6oTDFwi6bEutYQJ40o"
