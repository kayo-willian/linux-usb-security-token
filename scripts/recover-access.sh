#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"

if [[ ${1:-} == '--help' ]]; then
    printf 'Usage: sudo bash scripts/recover-access.sh\nAfter confirmation and backup, comments only the mandatory GDM USB rule.\n'
    exit 0
fi
[[ $# == 0 ]] || fail 'Unknown argument; use --help.'
require_root
require_terminal
require_command python3
require_command cmp

if python3 "$SCRIPT_DIR/lib/edit-gdm.py" /etc/pam.d/gdm-password --check; then
    :
else
    result=$?
    if (( result == 3 )); then
        exit 0
    fi
    exit "$result"
fi
[[ -r /etc/pam.d/common-auth ]] || fail 'common-auth missing or unreadable; review manually.'
if grep -Eq '^[[:space:]]*auth[[:space:]].*pam_usb\.so' /etc/pam.d/common-auth; then
    fail 'pam_usb is active in common-auth. This helper covers Method 02 Part 02 only; review global authentication manually.'
fi
printf '\nThis operation removes the USB requirement from gdm-password.\n'
printf 'It does not directly unlock the screen or change the udev removal lock rule.\n'
if ! confirm 'Review the proposed change and confirm recovery:'; then
    printf 'Cancelled. No configuration was modified.\n'
    exit 0
fi
create_backup
cmp -s "$CREATED_BACKUP/pam.d/gdm-password" /etc/pam.d/gdm-password || fail 'gdm-password changed after backup; the recovery helper made no change.'
python3 "$SCRIPT_DIR/lib/edit-gdm.py" /etc/pam.d/gdm-password
printf '\nBackup created before recovery: %s\n' "$CREATED_BACKUP"
printf 'Return to GDM and begin a new password authentication attempt. Restarting GDM is unnecessary.\n'
printf 'To re-enable: edit gdm-password, uncomment only the USB rule and rerun the tests.\n'
printf 'Do not re-enable the global USB profile from Part 01. See Method 02 Part 02.\n'
