#!/usr/bin/env bash
# Shared functions; do not run directly.

fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

require_root() {
    (( EUID == 0 )) || fail 'Run this script with sudo.'
}

require_terminal() {
    [[ -t 0 && -t 1 ]] || fail 'Run in an interactive terminal; do not pipe confirmation answers.'
}

confirm() {
    local resposta
    printf '%s\n' "$1"
    read -r -p 'Type CONFIRM to continue (Enter cancels): ' resposta || return 1
    [[ "$resposta" == 'CONFIRM' ]]
}

create_backup() {
    # Call directly, not via $(...), so CREATED_BACKUP stays available.
    require_root
    require_command mktemp
    local item source_path target_name
    local -a entries=(
        'pam.d:/etc/pam.d'
        'libpam-usb:/usr/share/pam-configs/libpam-usb'
        '80-usb.rules:/etc/udev/rules.d/80-usb.rules'
        'usb-lock.sh:/usr/local/bin/usb-lock.sh'
        'pam_usb.conf:/etc/security/pam_usb.conf'
    )
    [[ -d /etc/pam.d && -f /etc/pam.d/gdm-password ]] || fail 'GDM PAM configuration not found.'
    CREATED_BACKUP=$(mktemp -d /root/usb-token-backup.XXXXXX)
    chmod 700 "$CREATED_BACKUP"
    printf 'Backup created at %s\nUTC date: %s\n' "$CREATED_BACKUP" "$(date -u +%FT%TZ)" > "$CREATED_BACKUP/RECORD.txt"
    for item in "${entries[@]}"; do
        target_name=${item%%:*}
        source_path=${item#*:}
        if [[ -e "$source_path" || -L "$source_path" ]]; then
            if ! cp -a -- "$source_path" "$CREATED_BACKUP/$target_name"; then
                printf 'INCOMPLETE: failed to copy %s\n' "$source_path" >> "$CREATED_BACKUP/RECORD.txt"
                fail "incomplete backup at $CREATED_BACKUP; no authentication settings were changed."
            fi
            printf 'Copied: %s\n' "$source_path" >> "$CREATED_BACKUP/RECORD.txt"
        else
            printf 'Missing: %s\n' "$source_path" >> "$CREATED_BACKUP/RECORD.txt"
        fi
    done
    printf 'Complete. USB pads were not copied.\n' >> "$CREATED_BACKUP/RECORD.txt"
    printf 'Backup completed: %s\n' "$CREATED_BACKUP"
}
