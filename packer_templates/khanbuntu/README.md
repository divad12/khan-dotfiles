# Khanbuntu Developer Box

## Overview

The khanbuntu box is meant to be a reference VM that is maintained
to validate devops supported development environment. This includes
the scripts we use to create the dev environment.

### TODO

* TODO(ericbrown): This readme should probably only address building and 
  publishing box(es) and leave vagrant documentation elsewhere.
* TODO(ericbrown): Document risk of ISO file disappearing.
* TODO(ericbrown): Not sure activating ~/.virtualenv/khan27 is what we should
  want at this point.

## Building

    make

NB: This will launch virtualbox (including its GUI on mac) and take ~15+
minutes to build. Just let it finish and look for errors.

## Running

Go to a different directory

    vagrant init .../ubuntu-20.04.<timestamp>.virtualbox.box
    vagrant up
    vagrant ssh

## Dependencies

Use a package manager to install packer, vagrant and virtualbox 6+. On a mac,
you would run:

    brew install packer vagrant virtualbox

(Installing vagrant under OS X Catalina+ is non-trivial and a Confluence page
will be created with details.)

TODO(ericbrown): Add links to existing OS X virtualbox install instructions.

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
