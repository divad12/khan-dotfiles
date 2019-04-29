#!/bin/sh

# This installs binaries that you need to develop at Khan Academy.
# The OS-independent setup.sh assumes all this stuff has been
# installed.

# Bail on any errors
set -e

# Install in $HOME by default, but can set an alternate destination via $1.
ROOT=${1-$HOME}
mkdir -p "$ROOT"

# the directory all repositories will be cloned to
REPOS_DIR="$ROOT/khan"

# derived path location constants
DEVTOOLS_DIR="$REPOS_DIR/devtools"

# Load shared setup functions.
. "$DEVTOOLS_DIR"/khan-dotfiles/shared-functions.sh

trap exit_warning EXIT   # from shared-functions.sh

install_java() {
    # On 16.04LTS and some later versions we have openjdk-8, so install it directly.
    sudo apt-get install -y openjdk-8-jdk || {
        # On more recent versions, use the Azul Systems binary distribution of OpenJDK 8,
        # since Java 8 has been removed from the official packages.
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9
        sudo apt-add-repository -y 'deb http://repos.azulsystems.com/ubuntu stable main'
        sudo apt-get update
        sudo apt-get install -y zulu-8
    }
    # We ask you to select a java version (interactively) in case you have more
    # than one installed.  If there's only one, it'll just select that version
    # by default.
    sudo update-alternatives --config java
    sudo update-alternatives --config javac
}

# NOTE: if you add a package here, check if you should also add it
# to webapp's Dockerfile.
install_packages() {
    updated_apt_repo=""

    # This is needed to get the add-apt-repository command.
    # apt-transport-https may not be strictly necessary, but can help
    # for future updates.
    sudo apt-get install -y software-properties-common apt-transport-https

    # To get the most recent nodejs, later.
    if ls /etc/apt/sources.list.d/ 2>&1 | grep -q chris-lea-node_js; then
        # We used to use the (obsolete) chris-lea repo, remove that if needed
        sudo add-apt-repository -y -r ppa:chris-lea/node.js
        sudo rm -f /etc/apt/sources.list.d/chris-lea-node_js*
        updated_apt_repo=yes
    fi
    if ! ls /etc/apt/sources.list.d/ 2>&1 | grep -q nodesource || \
       ! grep -q node_8.x /etc/apt/sources.list.d/nodesource.list; then
        # This is a simplified version of https://deb.nodesource.com/setup_8.x
        wget -O- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
        cat <<EOF | sudo tee /etc/apt/sources.list.d/nodesource.list
deb https://deb.nodesource.com/node_8.x `lsb_release -c -s` main
deb-src https://deb.nodesource.com/node_8.x `lsb_release -c -s` main
EOF
        sudo chmod a+rX /etc/apt/sources.list.d/nodesource.list
        updated_apt_repo=yes
    fi

    # To get the most recent git, later.
    if ! ls /etc/apt/sources.list.d/ 2>&1 | grep -q git-core-ppa; then
        sudo add-apt-repository -y ppa:git-core/ppa
        updated_apt_repo=yes
    fi

    # To get chrome, later.
    if [ ! -s /etc/apt/sources.list.d/google-chrome.list ]; then
        echo "deb http://dl.google.com/linux/chrome/deb/ stable main" \
            | sudo tee /etc/apt/sources.list.d/google-chrome.list
        wget -O- https://dl-ssl.google.com/linux/linux_signing_key.pub \
            | sudo apt-key add -
        updated_apt_repo=yes
    fi

    # Register all that stuff we just did.
    if [ -n "$updated_apt_repo" ]; then
        sudo apt-get update -qq -y || true
    fi

    # Needed to develop at Khan: git, python, node (js).
    # php is needed for phabricator
    # lib{freetype6{,-dev},{png,jpeg}-dev} are needed for PIL
    # imagemagick is needed for image resizing and other operations
    # lib{xml2,xslt}-dev are needed for lxml
    # libyaml-dev is needed for pyyaml
    # libncurses-dev and libreadline-dev are needed for readline
    # nginx is used as a devserver proxy that serves static files
    # nodejs is used for various frontendy stuff in webapp, and
    #   we standardize on version 8.
    # TODO(benkraft): Pull the version we want from webapp somehow.
    # curl for various scripts (including setup.sh)
    sudo apt-get install -y git \
        python-dev \
        pychecker python-mode python-setuptools python-pip python-virtualenv \
        libfreetype6 libfreetype6-dev libpng-dev libjpeg-dev \
        imagemagick \
        libxslt1-dev \
        libyaml-dev \
        libncurses-dev libreadline-dev \
        nodejs=8* \
        nginx \
        curl

    # There are two different php packages, depending on if you're on Ubuntu
    # 14.04 LTS or 16.04 LTS, and neither version has both.  So we just try
    # both of them.  In 16.04+, php-xml is also a separate package, which we
    # need too.
    sudo apt install -y php-cli php-curl php-xml || sudo apt-get install -y php5-cli php5-curl

    # Ubuntu installs as /usr/bin/nodejs but the rest of the world expects
    # it to be `node`.
    if ! [ -f /usr/bin/node ] && [ -f /usr/bin/nodejs ]; then
        sudo ln -s /usr/bin/nodejs /usr/bin/node
    fi

    # Ubuntu's nodejs doesn't install npm, but if you get it from the PPA,
    # it does (and conflicts with the separate npm package).  So install it
    # if and only if it hasn't been installed already.
    if ! which npm >/dev/null 2>&1 ; then
        sudo apt-get install -y npm
    fi
    # Make sure we have the preferred version of npm
    # TODO(benkraft): Pull this version number from webapp somehow.
    sudo npm install -g npm@5.6.0

    # Get the latest slack deb file and install it.
    if ! which slack >/dev/null 2>&1 ; then
        case `uname -m` in
            *86) arch=i386;;
            x86_64) arch=amd64;;
            *) echo "WARNING: Cannot install slack: no client for `uname -m`";;
        esac
        if [ -n "$arch" ]; then
            sudo apt-get install -y gconf2 gconf-service libgtk2.0-0 libappindicator1
            rm -rf /tmp/slack.deb
            deb_url="$(wget -O- https://slack.com/downloads/instructions/ubuntu | grep -o 'https.*\.deb' | head -n1)"
            if [ -n "$deb_url" ]; then
                wget -O/tmp/slack.deb "$deb_url" || echo "WARNING: Cannot install slack: couldn't download $deb_url"
                sudo dpkg -i /tmp/slack.deb
            else
                echo "WARNING: Cannot install slack: couldn't find .deb URL"
            fi
        fi
    fi

    # Not technically needed to develop at Khan, but we assume you have it.
    sudo apt-get install -y unrar virtualbox ack-grep

    # Not needed for Khan, but useful things to have.
    sudo apt-get install -y ntp abiword curl diffstat expect gimp \
        mplayer netcat netpbm screen w3m vim emacs google-chrome-stable

    # If you don't have the other ack installed, ack is shorter than ack-grep
    # This might fail if you already have ack installed, so let it fail silently.
    sudo dpkg-divert --local --divert /usr/bin/ack --rename --add \
        /usr/bin/ack-grep || echo "Using installed ack"

    # Needed to install printer drivers, and to use the printer scanner
    sudo apt-get install -y apparmor-utils xsane

    # We use java for our google cloud dataflow jobs that live in webapp
    # (as well as in khan-linter for linting those jobs)
    install_java
}

install_protoc() {
    # We use protocol buffers in webapp's event log stream infrastructure. This
    # installs the protocol buffer compiler (which generates python & java code
    # from the protocol buffer definitions), as well as a go-based compiler
    # plugin that allows us to generate bigquery schemas as well.

    if ! which protoc >/dev/null; then
        # TODO(colin): I didn't see a good-looking ppa for the protbuf compiler.
        # Look a bit harder to see if there's a better way to keep this up to date?
        mkdir -p /tmp/protoc
        wget -O/tmp/protoc/protoc-3.5.0.zip https://github.com/google/protobuf/releases/download/v3.5.0/protoc-3.5.0-linux-x86_64.zip
        (
            cd /tmp/protoc
            unzip protoc-3.5.0.zip
            # This puts the compiler itself into ./bin/protoc and several
            # definitions into ./include/google/**
            # we move them both into /usr/local
            sudo install -m755 ./bin/protoc /usr/local/bin
            sudo mv ./include/google /usr/local/include/
            sudo chmod -R a+rX /usr/local/include/google
        )
        rm -fr /tmp/protoc
    else
        echo "protoc already installed"
    fi

    if ! which go >/dev/null; then
        # TODO(colin): should we check the version too? I don't know how
        # stringent the protobuf plugin requirements are on version.
        sudo add-apt-repository -y ppa:gophers/archive
        sudo apt-get update -qq -y
        sudo apt-get install -y golang-1.11
        # The ppa installs go into /usr/lib/go-1.11/bin/go
        # Let's link that to somewhere likely to be on $PATH
        sudo ln -snf /usr/lib/go-1.11/bin/go /usr/local/bin/go
    else
        echo "golang already installed"
    fi
    go get github.com/GoogleCloudPlatform/protoc-gen-bq-schema
}

setup_clock() {
    # This shouldn't be necessary, but it seems it is.
    if ! grep -q 3.ubuntu.pool.ntp.org /etc/ntp.conf; then
        sudo service ntp stop
        sudo ntpdate 0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org \
            2.ubuntu.pool.ntp.org 3.ubuntu.pool.ntp.org
        sudo service ntp start
    fi
}

config_inotify() {
    # webpack gets sad on webapp if it can only watch 8192 files (which is the
    # ubuntu default).
    echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
}

echo
echo "Running Khan Installation Script 1.1"
echo
# We grep -i to have a good chance of catching flavors like Xubuntu.
if ! lsb_release -is 2>/dev/null | grep -iq ubuntu ; then
    echo "This script is mostly tested on Ubuntu;"
    echo "other distributions may or may not work."
fi

if ! echo "$SHELL" | grep -q '/bash$' ; then
    echo
    echo "It looks like you're using a shell other than bash!"
    echo "Other shells are not officially supported.  Most things"
    echo "should work, but dev-support help is not guaranteed."
fi

# Run sudo once at the beginning to get the necessary permissions.
echo "This setup script needs your password to install things as root."
sudo sh -c 'echo Thanks'

install_packages
install_protoc
setup_clock
config_inotify

trap - EXIT
