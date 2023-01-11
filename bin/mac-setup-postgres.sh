#!/bin/bash

# TODO(ericbrown): remove by 1 April 2021 after mac-setup-postgres.py is proven
echo "This script is here for reference. Use mac-setup-postgres.py instead!"
exit 1

# Bail on any errors
set -e

SCRIPT=$(basename $0)

# This script is only for comparison with python version
echo "$SCRIPT: This script is deprecated: Try mac-setup-postgres.py"

if brew ls postgresql@14 >/dev/null 2>&1 ; then
  pg_brewname="postgresql@14"
elif brew ls postgresql --versions >/dev/null 2>&1 | grep "\s11\.\d" ; then
  # TODO(ericbrown): Why do we allow this?
  pg_brewname="postgresql"
else
  # We do not have pg11 installed
  pg_brewname="NONE"
fi

echo "$SCRIPT: Ensure postgres (usually 11) is installed and running"

if [ "$pg_brewname" = "NONE" ] ; then
  pg_brewname="postgresql@14"
  echo "$SCRIPT: Installing ${pg_brewname}"
  brew install ${pg_brewname}
  # swtich icu4c to 64.2
  # if default verison is 63.x and v64.2 was installed by postgres@11
  if [ "$(brew ls icu4c --versions |grep "icu4c 63")" ] && [ "$(brew ls icu4c | grep 64.2 >/dev/null 2>&1)" ]; then
    # TODO(ericbrown): I don't think we ever get here. (brew switch is deprecated)
    brew switch icu4c 64.2
  fi

  # Brew doesn't link non-latest versions on install. This command fixes that
  # allowing postgresql and commads like psql to be found
  brew link --force --overwrite ${pg_brewname}
else
  echo "$SCRIPT: ${pg_brewname} already installed"
fi

# Sometimes postgresql does not link (or gets unlinked for some reason)
which psql || brew link ${pg_brewname}

# Make sure that postgres is started, so that we can create the user below,
# if necessary and so later steps in setup_webapp can connect to the db.
if ! brew services list | grep "$pg_brewname" | grep -q started; then
  echo "$SCRIPT: Starting postgreql service"
  brew services start "$pg_brewname" 2>&1
  # Give postgres a chance to start up before we connect to it on the next line
  sleep 5
else
  echo "$SCRIPT: postgresql service already started"
fi

# We create a postgres user locally that we use in test and dev.
if ! psql -tc "SELECT rolname from pg_catalog.pg_roles"  postgres | grep -c 'postgres' > /dev/null 2>&1 ; then
  echo "$SCRIPT: Creating postgres user for dev"
  psql --quiet -c "CREATE ROLE postgres LOGIN SUPERUSER;" postgres;
else
  echo "$SCRIPT: postgres user already created"
fi
