# Temporarily disable USB authentication without deleting the configuration

[Português (Brasil)](DISABLE_USB_TOKEN.pt-BR.md) · [Project overview](README.md)

This guide covers the two mechanisms used by **Linux USB Security Token** on the documented Debian 13 / GNOME / GDM setup: (1) a USB removal rule that locks a graphical session, and (2) a **GDM-only** `pam_usb.so` requirement. It preserves the existing files so the operator can restore their prior configuration.

> **Important:** Read [Method 02 — Part 02](method-02/part-02.md) and have an accessible TTY, working password and a **verified backup** before modifying PAM. These are administrator procedures for the recorded host configuration; they have not been validated against every PAM layout. Do not re-enable the historical *system-wide USB authentication profile* from Part 01 as part of restoring the final Part 02 setup.

## 1. Access a TTY and back up the configuration

Press **Ctrl + Alt + F3** (on the recorded IdeaPad, **Ctrl + Alt + Fn + F3** may be needed), log in using the account password, and retain that recovery session. Create a private backup before making changes:

```bash
sudo -i
backup_dir=$(mktemp -d /root/usb-token-disabled.XXXXXX)
cp -a /etc/pam.d "$backup_dir/"
cp -a /etc/security/pam_usb.conf "$backup_dir/" 2>/dev/null || true
cp -a /etc/udev/rules.d/80-usb.rules "$backup_dir/" 2>/dev/null || true
cp -a /usr/share/pam-configs/libpam-usb "$backup_dir/" 2>/dev/null || true
cp -a /usr/local/bin/usb-lock.sh "$backup_dir/" 2>/dev/null || true
printf 'Backup: %s\n' "$backup_dir"
```

Check the copies and preserve the resulting path. Optional items may be absent; **do not treat a missing required PAM backup as success**. Backups may contain sensitive configuration: keep them private and do not commit them to Git.

## 2. Disable the USB requirement for GDM (Method 02)

In `/etc/pam.d/gdm-password`, locate the **single** active line:

```text
auth required pam_usb.so
```

Comment out only that line:

```text
# auth required pam_usb.so
```

Use `nano /etc/pam.d/gdm-password` from the root shell (or `sudo nano` outside it). Save the file with Ctrl + O, Enter, Ctrl + X. Preserve all other PAM lines. A fresh graphical authentication attempt should then accept the account password without the USB token, **provided no other authentication policy requires it**. You do not need to restart GDM.

**Do not blindly run `pam-auth-update --enable libpam-usb`** to re-enable this setup. The final configuration keeps the historical global USB profile disabled and instead applies USB authentication only to `gdm-password`.

## 3. Disable the USB removal lock (Method 01)

Inspect the local rule before editing:

```bash
nano /etc/udev/rules.d/80-usb.rules
```

Find **the specific** `ACTION=="remove"` rule that invokes `/usr/local/bin/usb-lock.sh lock`, and comment out that line while preserving the rest of the file. For example:

```udev
# ACTION=="remove", ... RUN+="/usr/local/bin/usb-lock.sh lock"
```

The `...` in this example is **illustrative, not executable udev syntax**. Keep the actual device-matching attributes and line intact after the `#`. Do not remove unrelated rules. Reload the changed rules:

```bash
udevadm control --reload-rules
```

This stops **future** removal events from requesting a lock. It does not automatically unlock an already locked session or reverse a previous PAM authentication failure. The historical Method 01 `unlock` rule should already be disabled in the final Part 02 state; do not reintroduce automatic unlock.

## 4. Check the resulting configuration

```bash
grep -n 'pam_usb.so' /etc/pam.d/gdm-password || true
grep -n 'usb-lock.sh' /etc/udev/rules.d/80-usb.rules || true
```

The relevant `pam_usb.so` and `usb-lock.sh lock` lines should be **comments**. Inspect the entire matching lines before concluding; these greps do not verify whether other services or rules still enforce USB.

Return to GDM using the correct VT for your machine (often VT 2, sometimes VT 1). From the root shell, `chvt 2` may switch to VT 2. Start a **new** graphical login/unlock attempt with the password and USB absent. Keep TTY recovery access available until the result is confirmed.

## 5. Re-enable the final USB + password policy

Restore **only** the previously disabled GDM line, with exactly one active `auth required pam_usb.so` immediately before `@include common-auth`. If desired, restore the previously active `udev` removal-lock line and reload rules:

```bash
udevadm control --reload-rules
```

Re-enabling the USB rule without confirming a functioning registered token risks lockout. Repeat the positive and negative tests from [Method 02 — Part 02](method-02/part-02.md) and verify that TTY login still uses the password. **Do not enable** the obsolete global `libpam-usb` profile from Part 01 for this final setup; that would restore a different authentication policy.

## 6. Scope and recovery notes

- The GDM requirement and the udev session-lock rule are **separate**. Disabling one does not disable the other.
- These edits disable specific rules; they **do not uninstall** `pam_usb`, erase pads or change registered device data.
- The [interactive recovery script](scripts/README.md) can comment out only the GDM USB rule after confirmation and a backup; it does not touch the udev removal rule or perform complete restoration.
- If your configuration differs from the recorded Method 02 — Part 02, stop and inspect your PAM stack before proceeding. Do not apply historical methods blindly to a live host.
