# About scripts

These scripts are numbered in the order we want to run them.

There are a few special scripts that must be run individually by packer.
(Anything that causes a reboot has to be run separately.)
* **01-update.sh** - This tweaks apt and reboots
* **05-run-numbered-scripts.sh** - This runs all the XXX-scripts

XXX-scripts:
* 100-199 Were originally borrowed from the public bento project. They are
  not necessarily all needed.
* 200-299 Khan Academy customizations
* 800-899 Were originally borrowed from public bento project.

See [khanbuntu.pkr.hcl](../khanbuntu.pkr.hcl).
