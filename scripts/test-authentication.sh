#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"

if [[ ${1:-} == '--help' ]]; then
    printf 'Usage: sudo bash scripts/test-authentication.sh [account]\nGuides three real pamtester checks against gdm-password.\n'
    exit 0
fi
[[ $# -le 1 ]] || fail 'Provide only one user name.'
require_root
require_terminal
require_command pamtester
require_command getent
account=${1:-${SUDO_USER:-}}
[[ -n "$account" && "$account" != root ]] || fail 'Provide the registered non-root account, e.g. sudo bash scripts/test-authentication.sh henrique'
[[ "$account" =~ ^[a-zA-Z_][a-zA-Z0-9_.-]*\$?$ ]] || fail 'Invalid user name.'
getent passwd "$account" >/dev/null || fail 'User not found.'
[[ -r /etc/pam.d/gdm-password ]] || fail 'gdm-password PAM service not found.'
if ! grep -Eq '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_usb\.so([[:space:]]|$)' /etc/pam.d/gdm-password; then
    fail 'Mandatory USB rule missing from GDM; check Method 02 Part 02 before testing.'
fi
[[ -r /etc/pam.d/common-auth ]] || fail 'common-auth missing or unreadable; review manually.'
if grep -Eq '^[[:space:]]*auth[[:space:]].*pam_usb\.so' /etc/pam.d/common-auth; then
    fail 'USB profile still active in common-auth; check Method 02 Part 02.'
fi
printf 'Account under test: %s\nService: gdm-password\n' "$account"
printf 'Enter the password only at the pamtester prompt. This script does not store it.\n'
printf 'Prefer a TTY; removing the USB may lock the graphical session.\n'
printf 'Finish writes and unmount before removing the USB drive.\n'
printf 'pam_usb verification may renew pads. This script does not edit PAM files.\n'
if ! confirm 'Start the three tests?'; then
    printf 'Tests cancelled.\n'
    exit 0
fi

declare -a exit_codes=()
declare -a results=()
for number in 1 2 3; do
    printf '\n=== Test %s of 3 ===\n' "$number"
    case "$number" in
        1) printf 'Connect the registered USB. Enter the CORRECT password for %s.\n' "$account" ;;
        2) printf 'Keep the USB connected. Enter a deliberately INCORRECT password.\n' ;;
        3) printf 'Unmount and remove the USB. Enter the CORRECT password for %s.\n' "$account" ;;
    esac
    read -r -p 'Press Enter when ready (Ctrl+C cancels): ' _ || fail 'Input ended; test interrupted.'
    if pamtester gdm-password "$account" authenticate; then
        code=0
        result='SUCCESS'
    else
        code=$?
        result='FAILURE'
    fi
    exit_codes+=("$code")
    results+=("$result")
    printf 'Observed outcome: %s (exit code %s).\n' "$result" "$code"
    if (( number == 1 && code != 0 )); then
        printf 'Positive test failed; stopping to check USB, pads and password.\n' >&2
        exit 1
    fi
    if (( number > 1 && code == 0 )); then
        printf 'Unexpected success. Recheck physical USB state, entered password and PAM configuration.\n' >&2
        exit 1
    fi
done
printf '\n=== Summary ===\n'
printf 'USB + correct password: %s\nUSB + incorrect password: %s\nSem USB + correct password: %s\n' "${results[0]}" "${results[1]}" "${results[2]}"
printf 'Results match the plan only if you followed each physical test condition.\n'
printf 'A negative result may also indicate a service error; review the messages above.\n'
printf 'Graphical login, unplug/replug, logout and reboot still require manual validation under Method 02 Part 02.\n'
