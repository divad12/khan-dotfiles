#!/bin/sh

set -e

BASHRC=/home/vagrant/.bashrc
PROFILE=/home/vagrant/.profile

PREFIX=$(cat <<EOF
# Include KA's bashisms if present
if [ -s ~/.bashrc.khan ]; then
    source ~/.bashrc.khan
fi

EOF
)

cp ${BASHRC} ${BASHRC}.bak
echo "${PREFIX}\n$(cat ${BASHRC})" > ${BASHRC}

cp ${PROFILE} ${PROFILE}.bak
echo "if [ -s ~/.profile.khan ]; then . ~/.profile.khan; fi\n$(cat ${PROFILE})" > ${PROFILE}
