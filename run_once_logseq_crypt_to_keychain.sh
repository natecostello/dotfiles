#!/bin/bash
set -euo pipefail

NAME="rclone/logseq_crypt_passphrase"          # LastPass item name
SERVICE="rclone/logseq/crypt_passphrase"       # Keychain service name

# Fetch the passphrase from LastPass and store/update it in Keychain (login keychain)
PASS="$(lpass show --password "$NAME")"
security add-generic-password -a "$USER" -s "$SERVICE" -w "$PASS" -U

echo "Saved passphrase to Keychain service: $SERVICE"
