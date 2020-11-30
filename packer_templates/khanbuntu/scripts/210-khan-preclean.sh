#!/bin/sh

# Get rid of things that might have accidentally gotten installed in the
# normal course of setup.

# TODO(ericbrown): We are a python2 shop. Get rid of pesky python3 rubbish

# Unfortunately, something (ssh, virtualbox, vagrant?) depends on some part
# of python3. We cannot get rid of it completely.
# It ALSO appears some other 3rd party Khan tools fail without python3

# bash syntax:
#PKGS=()
#PKGS+=("python3.8-minimal")
#PKGS+=("libpython3-stdlib")
#PKGS+=("python3-minimal")

echo "We CANNOT remove python3 due to dependencies"
#apt-get remove -y ${PKGS[@]}
