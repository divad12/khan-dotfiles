#!/bin/sh -eux

welcome='
This system is for Khan Academy developers.
For help, contact @dev-support.'

if [ -d /etc/update-motd.d ]; then
    MOTD_CONFIG='/etc/update-motd.d/99-khanacademy'

    cat >> "$MOTD_CONFIG" <<BENTO
#!/bin/sh

cat <<'EOF'
$welcome
EOF
BENTO

    chmod 0755 "$MOTD_CONFIG"
else
    echo "$welcome" >> /etc/motd
fi
