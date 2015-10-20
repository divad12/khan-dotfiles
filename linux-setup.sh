#!/bin/sh

# This installs binaries that you need to develop at Khan Academy.
# The OS-independent setup.sh assumes all this stuff has been
# installed.

# Bail on any errors
set -e


install_packages() {
    updated_apt_repo=""

    # This is needed to get the add-apt-repository command.
    sudo apt-get install -y software-properties-common

    # To get the most recent nodejs, later.
    if ! ls /etc/apt/sources.list.d/ 2>&1 | grep -q chris-lea-node_js; then
        # We used to use the (obsolete) chris-lea repo, remove that if needed
        sudo add-apt-repository -y -r ppa:chris-lea/node.js
        # This is a simplified version of https://deb.nodesource.com/setup_4.x
        wget -O- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
        cat <<EOF | sudo tee /etc/apt/sources.list.d/nodesource.list
deb https://deb.nodesource.com/node_4.x `lsb_release -c -s` main
deb-src https://deb.nodesource.com/node_4.x `lsb_release -c -s` main
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
    # lib{xml2,xslt}-dev are needed for lxml
    sudo apt-get install -y git git-svn subversion \
        python-dev \
        pychecker python-mode python-setuptools python-pip python-virtualenv \
        libfreetype6 libfreetype6-dev libpng-dev libjpeg-dev \
        libxslt1-dev \
        libncurses-dev \
        nodejs \
        php5-cli php5-curl

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

    # TODO(william, mroth): replace this with the native Linux Slack client
    # once that's been released
    npm install -g plaidchat || sudo npm install -g plaidchat

    # For Ubuntu/Mint-like distros, add a desktop entry.
    if [ -d "$HOME/.local/share/applications" ]; then
        plaidchat="$(which plaidchat)"
        plaidchat_dir="$(dirname "$(readlink -f "$plaidchat")")"
        cat > "$HOME/.local/share/applications/plaidchat.desktop" <<EOF
[Desktop Entry]
Comment=Unofficial Slack client
Terminal=false
Name=PlaidChat
Exec=$plaidchat
Type=Application
Icon=$plaidchat_dir/app/images/app-256.png
EOF
    fi

    # Not technically needed to develop at Khan, but we assume you have it.
    sudo apt-get install -y unrar virtualbox ack-grep

    # This is useful for profiling
    # cf. https://sites.google.com/a/khanacademy.org/forge/technical/performance/using-kcachegrind-qcachegrind-with-gae_mini_profiler-results
    sudo apt-get install -y kcachegrind

    # Not needed for Khan, but useful things to have.
    sudo apt-get install -y ntp abiword curl diffstat expect gimp \
        imagemagick mplayer netcat netpbm screen w3m vim emacs \
        google-chrome-stable

    # If you don't have the other ack installed, ack is shorter than ack-grep
    # This might fail if you already have ack installed, so let it fail silently.
    sudo dpkg-divert --local --divert /usr/bin/ack --rename --add \
        /usr/bin/ack-grep || echo "Using installed ack"

    # Needed to install printer drivers, and to use the printer scanner
    sudo apt-get install -y apparmor-utils xsane
}

install_phantomjs() {
    if ! which phantomjs >/dev/null; then
        (
            cd /usr/local/share
            case `uname -m` in
                i?86) mach=i686;;
                *) mach=x86_64;;
            esac
            sudo rm -rf phantomjs
            wget "https://phantomjs.googlecode.com/files/phantomjs-1.9.2-linux-${mach}.tar.bz2" -O- | sudo tar xfj -

            sudo ln -snf /usr/local/share/phantomjs-1.9.2-linux-${mach}/bin/phantomjs /usr/local/bin/phantomjs
        )
        which phantomjs >/dev/null
    fi
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


# Run sudo once at the beginning to get the necessary permissions.
echo "This setup script needs your password to install things as root."
sudo sh -c 'echo Thanks'

install_packages
install_phantomjs
setup_clock
