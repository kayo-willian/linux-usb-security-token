#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"

if [[ ${1:-} == '--help' ]]; then
    printf 'Usage: bash scripts/menu.sh\nMenu for diagnostics, backups, authentication tests and recovery.\n'
    exit 0
fi
[[ $# == 0 ]] || fail 'Unknown argument; use --help.'
require_terminal

run_as_admin() {
    if (( EUID == 0 )); then
        bash "$@"
    else
        require_command sudo
        sudo bash "$@"
    fi
}

while true; do
    printf '\nLinux USB Security Token\n'
    printf '1. View diagnostics\n2. Create backup\n3. Test authentication\n4. Recover graphical login\n0. Exit\n'
    read -r -p 'Choice: ' choice || exit 0
    case "$choice" in
        1) bash "$SCRIPT_DIR/diagnostics.sh" || printf 'Diagnostics finished with an error.\n' ;;
        2) run_as_admin "$SCRIPT_DIR/backup.sh" || printf 'Backup finished with an error.\n' ;;
        3)
            read -r -p "Registered user [${SUDO_USER:-${USER:-henrique}}]: " account || exit 0
            account=${account:-${SUDO_USER:-${USER:-henrique}}}
            run_as_admin "$SCRIPT_DIR/test-authentication.sh" "$account" || printf 'Test interrupted or finished with an error; review the messages.\n'
            ;;
        4) run_as_admin "$SCRIPT_DIR/recover-access.sh" || printf 'Recovery finished with an error; review the messages.\n' ;;
        0) exit 0 ;;
        *) printf 'Invalid choice.\n' ;;
    esac
done
