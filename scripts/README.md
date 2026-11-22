# Interactive project tools

Helper scripts for a host that has already been configured according to [Method 02 — Part 02](../method-02/part-02.md). They provide diagnostics, backups, guided authentication testing and a cautious GDM recovery helper; **they do not install pam_usb or configure the complete method**.

## Start with the menu

From the repository root:

\`\`\`bash
bash scripts/menu.sh
\`\`\`

Run the menu as a regular user. Administrative options request \`sudo\`. If you are using a root TTY, specify the actual registered, non-root account for the authentication tests.

| Menu option | Script | Effect |
| --- | --- | --- |
| Diagnostics | \`diagnostics.sh\` | Reads environment, volumes, tools, PAM settings, rules and sessions |
| Backup | \`backup.sh\` | Copies configuration into a private directory under \`/root\` |
| Authentication tests | \`test-authentication.sh\` | Interactively runs three actual \`pamtester\` attempts |
| Recovery | \`recover-access.sh\` | After confirmation and backup, comments the mandatory GDM USB rule |

The scripts can also be run individually from the repository root:

\`\`\`bash
bash scripts/diagnostics.sh
sudo bash scripts/backup.sh
sudo bash scripts/test-authentication.sh henrique
sudo bash scripts/recover-access.sh
\`\`\`

The top-level scripts accept \`--help\`. Using \`bash\` does not require adding an executable bit to the scripts.

## Dependencies

The recorded environment is Debian 13, Bash, basic system utilities and Python 3. Only the actual authentication tests need \`pamtester\`:

\`\`\`bash
sudo apt update
sudo apt install -y pamtester
\`\`\`

The registered account and USB device must already be configured using \`pam_usb\`. No script silently installs dependencies or modifies the live authentication setup just by displaying help.

## Diagnostics

\`diagnostics.sh\` is read-only. It does **not** authenticate with the USB device or renew its pads. It reports settings and tool availability without printing the \`pam_usb\` XML or pad contents. Outputs may still contain account names, USB device metadata or other sensitive context; review before sharing.

Seeing a matching PAM or udev line does **not** prove that authentication works.

## Backup

\`backup.sh\` creates a private directory named like \`/root/usb-token-backup.XXXXXX\` (mode \`700\`) and records copied or absent files. It backs up:

- \`/etc/pam.d/\`
- \`/usr/share/pam-configs/libpam-usb\`, if present
- \`/etc/udev/rules.d/80-usb.rules\`, if present
- \`/usr/local/bin/usb-lock.sh\`, if present
- \`/etc/security/pam_usb.conf\`, if present

It does **not** back up USB pads, \`/etc/shadow\` or unrelated user data. Keep the backup private; it is not a full system backup or an automatic restore point.

## Guided authentication tests

Use a TTY if possible (Ctrl + Alt + F3, or Ctrl + Alt + Fn + F3 on the documented laptop). Removing the USB may lock the GNOME session. The script invokes \`pamtester gdm-password USER authenticate\` under three manually prepared conditions:

1. USB connected, correct password: **success** expected.
2. USB connected, incorrect password: **failure** expected.
3. USB absent, correct password: **failure** expected.

The script does not capture passwords; \`pamtester\` requests them. However, a real authentication request **may renew USB pads**. Finish writes and safely unmount the flash drive before disconnecting it.

The script stops early when the positive case fails or a negative case unexpectedly succeeds. A negative result can also reflect a service error; review the message and exit status. Graphical login, removal locking, reconnection, logout and reboot remain **manual** checks documented in Part 02.

## Recovery

Use the TTY and the actual account password, then run \`sudo bash scripts/recover-access.sh\`. The helper:

1. Checks that **exactly one** \`auth required pam_usb.so\` rule is active in \`gdm-password\`.
2. Refuses other active USB authentication rules and USB rules in shared \`common-auth\`.
3. Shows the proposed change and requires the exact interactive confirmation word \`CONFIRM\`.
4. Creates a private configuration backup.
5. Comments only the mandatory USB rule in \`gdm-password\`, preserving other lines, file ownership and permissions.

The Python editor writes to a temporary file in the same directory and uses atomic replacement. It refuses symlinks and ambiguous PAM rules. If the rule has already been commented out, it makes no change.

The recovery helper **does not** unlock a session, restart GDM, disable the udev lock-on-removal rule, or restore the whole system. Return to the graphical interface and begin a new password authentication attempt. To re-enable the final policy, restore only the GDM-specific rule and rerun the tests. Do **not** restore the historical global USB profile from Part 01.

## Offline development checks

\`\`\`bash
python3 -m unittest discover -s tests -v
\`\`\`

These checks use temporary files and exercise the PAM editor, suspicious rule rejection, preserved line endings/permissions, repeat invocation, Bash syntax, and script help. They do **not** authenticate against a real PAM stack or require a physical USB device.

The editor is \`scripts/lib/edit-gdm.py\`. Common shell utilities live in \`scripts/lib/common.sh\`; neither is an independent menu option.
