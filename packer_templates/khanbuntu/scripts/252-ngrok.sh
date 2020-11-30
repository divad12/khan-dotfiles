#!/bin/sh

set -e

# NAT traversal utility to help dev-support debug systems
# See https://dashboard.ngrok.com/
NGROK_ZIP=/tmp/ngrok.zip
wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -O ${NGROK_ZIP}
unzip ${NGROK_ZIP} ngrok -d /usr/local/bin
