#!/bin/sh -eux

# Add a welcome message when a user
# When a user does "vagrant ssh" they will see this message on their display.
# It is important when DevOps is helping a user with their system that they
# be able to identify the version of the VM the develper is using.

oldwelcome='
This system is for Khan Academy developers. Build ${BUILD_STAMP}.
For help, contact @dev-support on slack.'

# TODO(ericbrown): Figure out why BUILD_STAMP in khanbuntu.pkr.hcl doesn't work
# TODO(ericbrown): We really want monotomic version numbers as artifacts
SETUP_DIR=/usr/local/var/packer
welcome=$(cat ${SETUP_DIR}/khanmotd.txt)

if [ -d /etc/update-motd.d ]; then
    MOTD_CONFIG='/etc/update-motd.d/99-khanacademy'

    cat >> "$MOTD_CONFIG" <<KHANACADEMY
#!/bin/sh

cat <<'EOF'
$welcome
EOF
KHANACADEMY

    chmod 0755 "$MOTD_CONFIG"
else
    echo "$welcome" >> /etc/motd
fi
