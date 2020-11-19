# Packer Templates

## Overview

We are using [Packer](https://www.packer.io/) to build
[Vagrant](https://www.vagrantup.com/) development boxes.

The purpose of initial commits is only to preserve history as we take small 
steps to integrate [linux-setup.sh](../linux-setup.sh).

TODO(ericbrown): This readme should probably only address building and 
publishing box(es) and leave vagrant documentation elsewhere.

TODO(ericbrown): Document risk of ISO file disappearing.

## Building

TODO(ericbrown): This is only a POC (i.e. it will change)

    cd ubuntu
    packer build ubuntu-20.04-amd64.json

NB: This will launch virtualbox (including its GUI on mac) and take ~10+
minutes to build. Just let it finish and look for errors.

## Running

TODO(ericbrown): Put a deeper explanation here 

Go to a different directory

    vagrant init .../ubuntu-20.04.virtualbox.box
    vagrant up
    vagrant ssh

## Dependencies

Use a package manager to install packer, vagrant and virtualbox 6+. On a mac,
you would run:

    brew install packer vagrant virtualbox

(Installing vagrant under OS X Catalina+ is non-trivial and a Confluence page
will be created with details.)

TODO: Add links to existing OS X virtualbox install instructions.

## VM Space Used

On a mac, virtualbox's default VM location is `~/VirtualBox VMs`. Reach out
to @dev-support if you need help with this.

## Links

* [https://www.packer.io]()

## Attribution

These templates started from [Bento](https://github.com/chef/bento) templates.
I started with these only because some things changed in ubuntu 20.04.1 initial
auth that these templates addressed. They were also decently developed packer
templates.

License: Apache License 2.0

Other useful resources:
* [Ubuntu 20.04 Vagrant with Packer](https://www.neilgrogan.com/vagrant-ubuntu-fossa/)
  (does not deal with preseed.cfg)
