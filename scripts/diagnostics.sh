#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"

if [[ ${1:-} == '--help' ]]; then
    printf 'Usage: bash scripts/diagnostics.sh\nRead-only environment checks; does not modify PAM, rules, mounts or pads.\n'
    exit 0
fi
[[ $# == 0 ]] || fail 'Unknown argument; use --help.'

printf '\n=== System ===\n'
if [[ -r /etc/os-release ]]; then
    grep -E '^(PRETTY_NAME|VERSION_ID|VERSION_CODENAME)=' /etc/os-release || true
fi
printf 'Terminal user: %s\n' "$(id -un)"
printf 'Reported session type: %s\n' "${XDG_SESSION_TYPE:-not reported}"

printf '\n=== Disks and volumes ===\n'
if command -v lsblk >/dev/null 2>&1; then
    lsblk -o NAME,TRAN,SIZE,FSTYPE,UUID,MOUNTPOINTS,MODEL || printf 'Could not inspect volumes.\n'
fi

printf '\n=== Tools ===\n'
for tool in pamusb-check pamusb-conf pamtester loginctl udevadm python3; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '%s: available\n' "$tool"
    else
        printf '%s: missing\n' "$tool"
    fi
done

printf '\n=== Shared PAM: active auth lines ===\n'
if [[ -r /etc/pam.d/common-auth ]]; then
    grep -nE '^[[:space:]]*auth[[:space:]]' /etc/pam.d/common-auth || true
else
    printf 'File missing or not readable.\n'
fi
printf '\n=== GDM: authentication rules and includes ===\n'
if [[ -r /etc/pam.d/gdm-password ]]; then
    grep -nE '^[[:space:]]*(auth[[:space:]]|@include[[:space:]])' /etc/pam.d/gdm-password || true
else
    printf 'File missing or not readable.\n'
fi

printf '\n=== Active local USB rules ===\n'
if [[ -r /etc/udev/rules.d/80-usb.rules ]]; then
    grep -nE '^[[:space:]]*[^#[:space:]]' /etc/udev/rules.d/80-usb.rules || true
else
    printf '80-usb.rules missing or not readable.\n'
fi
printf '\n=== pam_usb XML ===\n'
if [[ -e /etc/security/pam_usb.conf ]]; then
    printf 'Found /etc/security/pam_usb.conf; XML and pad contents will not be printed.\n'
else
    printf '/etc/security/pam_usb.conf missing.\n'
fi
printf '\n=== Running agent ===\n'
if command -v pgrep >/dev/null 2>&1; then
    pgrep -af '[p]amusb-agent' || printf 'No pamusb-agent process found.\n'
fi
printf '\n=== Sessions ===\n'
if command -v loginctl >/dev/null 2>&1; then
    loginctl list-sessions --no-pager || printf 'Could not inspect logind.\n'
fi
printf '\nDiagnostics complete. Matching rules do not prove working or secure authentication.\n'
printf 'This script does not call pamusb-check: USB checks may renew pads.\n'
printf 'Redact identifiers and personal information before sharing output.\n'
