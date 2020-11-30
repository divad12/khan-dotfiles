#!/bin/sh -eux

# SCRIPTS_DIR is the location khanbuntu.pkr.hcl copies scripts
SETUP_DIR=/usr/local/var/packer
SCRIPTS_DIR=${SETUP_DIR}/scripts/

echo "Running all scripts - ${SCRIPTS_DIR}[1-9]*.sh"

for script in ${SCRIPTS_DIR}[1-9]*.sh; do
  echo "Running ${script}"
  . ${script}
done
