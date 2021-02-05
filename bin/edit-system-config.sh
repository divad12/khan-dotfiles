#!/bin/bash

# History:
# * Functionality moved from setup.sh to edit-system-config.sh
#   (called from linux-setup.sh and mac-setup-elevated.sh).

# Bail on any errors
set -e

# Install in $HOME by default, but can set an alternate destination via $1.
ROOT=${1-$HOME}
mkdir -p "$ROOT"

echo "Modifying system configs"

# This command avoids the spew when you deploy the Khan Academy
# appengine app:
#   Cannot guess mime-type for XXX.  Using application/octet-stream
line="application/octet-stream  less eot ttf woff otf as fla sjs flash tmpl"
if [ -s /usr/local/etc/mime.types ]; then
    # Replace any existing line with 'less' and 'eot' with the new line.
    grep -v 'less eot' /usr/local/etc/mime.types | \
        sudo sh -c "cat; echo '$line' > /usr/local/etc/mime.types"
else
    sudo sh -c 'echo "$line" > /usr/local/etc/mime.types'
fi
sudo chmod a+r /usr/local/etc/mime.types

# If there is no ssh key, make one.
mkdir -p "$ROOT/.ssh"
if [ ! -e "$ROOT/.ssh/id_rsa" -a ! -e "$ROOT/.ssh/id_dsa" ]; then
    ssh-keygen -q -N "" -t rsa -f "$ROOT/.ssh/id_rsa"
fi

# if the user does not have a global gitignore file configured, reference
# ours (or whatever is in the default location
if ! git config --global core.excludesfile > /dev/null; then
    git config --global core.excludesfile ~/.gitignore
fi
# cleanup from previous versions: remove ~/.gitignore.khan symlink if exists
rm -f ~/.gitignore.khan

# Apple is very picky on permsions of files zsh loads
ZSHSHARE="/usr/local/share/zsh"
if [[ -d "${ZSHSHARE}" ]]; then
    chmod -R 755 "${ZSHSHARE}"
fi
