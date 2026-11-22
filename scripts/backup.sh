#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"

if [[ ${1:-} == '--help' ]]; then
    printf 'Usage: sudo bash scripts/backup.sh\nCopies configuration to a private directory under /root; does not change authentication.\n'
    exit 0
fi
[[ $# == 0 ]] || fail 'Unknown argument; use --help.'
create_backup
printf 'Keep this path private. The backup contains PAM configuration; do not publish it.\n'
printf 'See Method 02 Part 02 for rollback. This script does not restore files automatically.\n'
