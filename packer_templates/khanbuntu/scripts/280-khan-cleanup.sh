#!/bin/sh

# Stop or remove anything specific to Khan Academy

# We don't want the system nginx running on port 80
systemctl disable nginx
systemctl stop nginx

# TODO(ericbrown): Do we want to disable redis & postgresql too? others?

HOME=/home/vagrant
chown -R vagrant.vagrant ${HOME}/.[a-z]*
